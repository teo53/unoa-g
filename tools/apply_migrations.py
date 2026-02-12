#!/usr/bin/env python3
"""Apply Supabase migrations via Management API."""
import json
import os
import re
import sys
import urllib.request

PROJECT_REF = "sgkyerbmmexxsyrcsdzy"
ACCESS_TOKEN = os.environ.get("SUPABASE_ACCESS_TOKEN", "sbp_82462bbbf5a375eebf0b3c7ebfb102ee8c04c6d7")
API_URL = f"https://api.supabase.com/v1/projects/{PROJECT_REF}/database/query"

MIGRATIONS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "supabase", "migrations")


def run_query(sql: str) -> tuple[int, str]:
    """Execute SQL via Management API. Returns (http_code, response_body)."""
    data = json.dumps({"query": sql}).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=data,
        headers={
            "Authorization": f"Bearer {ACCESS_TOKEN}",
            "Content-Type": "application/json",
            "User-Agent": "supabase-migration-tool/1.0",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8")


def get_applied_versions() -> set[str]:
    """Get set of already-applied migration versions."""
    code, body = run_query(
        "SELECT version FROM supabase_migrations.schema_migrations ORDER BY version"
    )
    if code != 201:
        print(f"ERROR fetching versions: {body}")
        sys.exit(1)
    rows = json.loads(body)
    return {r["version"] for r in rows}


def get_migration_files() -> list[tuple[str, str, str]]:
    """Return sorted list of (version, name, filepath)."""
    files = []
    for f in sorted(os.listdir(MIGRATIONS_DIR)):
        if not f.endswith(".sql"):
            continue
        m = re.match(r"(\d+)_(.+)\.sql", f)
        if m:
            files.append((m.group(1), m.group(2), os.path.join(MIGRATIONS_DIR, f)))
    return files


def apply_migration(version: str, name: str, filepath: str) -> bool:
    """Apply a single migration. Returns True on success."""
    with open(filepath, "r", encoding="utf-8") as f:
        sql = f.read()

    code, body = run_query(sql)

    if code == 201:
        # Record in schema_migrations
        record_sql = (
            f"INSERT INTO supabase_migrations.schema_migrations(version, name) "
            f"VALUES('{version}', '{name}') ON CONFLICT DO NOTHING"
        )
        run_query(record_sql)
        return True
    else:
        try:
            msg = json.loads(body).get("message", body)
        except Exception:
            msg = body
        print(f"    ERROR: {msg[:300]}")
        return False


def main():
    applied = get_applied_versions()
    migrations = get_migration_files()

    print(f"Already applied: {sorted(applied)}")
    print(f"Total migration files: {len(migrations)}")
    print()

    success_count = 0
    fail_count = 0
    failed = []

    for version, name, filepath in migrations:
        if version in applied:
            continue

        filename = os.path.basename(filepath)
        print(f"  {filename}...", end=" ", flush=True)

        if apply_migration(version, name, filepath):
            print("OK")
            success_count += 1
        else:
            fail_count += 1
            failed.append(filename)

    print(f"\nResults: {success_count} applied, {fail_count} failed")
    if failed:
        print(f"Failed migrations: {', '.join(failed)}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
