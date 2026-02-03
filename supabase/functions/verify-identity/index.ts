// Edge Function: verify-identity
// Verifies PortOne PASS certification and stores encrypted PII
//
// SECURITY:
// - PortOne API secrets are stored in Supabase secrets (never exposed to client)
// - Raw PII is encrypted before storage
// - Client only receives verification flags and masked data

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// PortOne V2 API configuration
const PORTONE_API_SECRET = Deno.env.get("PORTONE_API_SECRET") || "";
const PORTONE_API_URL = "https://api.portone.io";

// Supabase configuration
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

// Encryption key for PII (should be rotated periodically)
const ENCRYPTION_KEY = Deno.env.get("PII_ENCRYPTION_KEY") || "";

interface PortOneIdentityResponse {
  identityVerification: {
    id: string;
    status: "VERIFIED" | "FAILED" | "PENDING";
    verifiedCustomer?: {
      name: string;
      phoneNumber: string;
      birthDate: string; // YYYY-MM-DD
      gender: "MALE" | "FEMALE";
      isForeigner: boolean;
      carrier: string;
      ci: string; // 연계정보
      di: string; // 중복가입확인정보
    };
    requestedAt: string;
    verifiedAt?: string;
  };
}

interface VerificationRequest {
  impUid: string;
}

interface VerificationResponse {
  success: boolean;
  imp_uid?: string;
  masked_phone?: string;
  is_adult?: boolean;
  is_at_least_14?: boolean;
  error_code?: string;
  error_message?: string;
}

// Simple AES-GCM encryption using Web Crypto API
async function encryptPII(plaintext: string, keyString: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(plaintext);

  // Derive key from string
  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    encoder.encode(keyString.padEnd(32, "0").slice(0, 32)),
    "AES-GCM",
    false,
    ["encrypt"]
  );

  // Generate random IV
  const iv = crypto.getRandomValues(new Uint8Array(12));

  // Encrypt
  const encrypted = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv },
    keyMaterial,
    data
  );

  // Combine IV + ciphertext and encode as base64
  const combined = new Uint8Array(iv.length + new Uint8Array(encrypted).length);
  combined.set(iv);
  combined.set(new Uint8Array(encrypted), iv.length);

  return btoa(String.fromCharCode(...combined));
}

// Mask phone number: 01012345678 -> ***-****-5678
function maskPhoneNumber(phone: string): string {
  const cleaned = phone.replace(/[^0-9]/g, "");
  if (cleaned.length >= 4) {
    return `***-****-${cleaned.slice(-4)}`;
  }
  return "***-****-****";
}

// Calculate age from birth date
function calculateAge(birthDate: string): number {
  const [year, month, day] = birthDate.split("-").map(Number);
  const today = new Date();
  let age = today.getFullYear() - year;

  const monthDiff = today.getMonth() + 1 - month;
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < day)) {
    age--;
  }

  return age;
}

// Verify identity with PortOne V2 API
async function verifyWithPortOne(impUid: string): Promise<PortOneIdentityResponse | null> {
  try {
    const response = await fetch(
      `${PORTONE_API_URL}/identity-verifications/${impUid}`,
      {
        method: "GET",
        headers: {
          "Authorization": `PortOne ${PORTONE_API_SECRET}`,
          "Content-Type": "application/json",
        },
      }
    );

    if (!response.ok) {
      console.error("PortOne API error:", response.status, await response.text());
      return null;
    }

    return await response.json();
  } catch (error) {
    console.error("PortOne API request failed:", error);
    return null;
  }
}

serve(async (req: Request) => {
  // CORS headers
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Parse request
    const { impUid } = await req.json() as VerificationRequest;

    if (!impUid) {
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "MISSING_IMP_UID",
          error_message: "인증 ID가 누락되었습니다.",
        } as VerificationResponse),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get user from JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "UNAUTHORIZED",
          error_message: "인증이 필요합니다.",
        } as VerificationResponse),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Create Supabase client with service role for database operations
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Also create client with user JWT to get user info
    const userClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "INVALID_USER",
          error_message: "사용자 정보를 확인할 수 없습니다.",
        } as VerificationResponse),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify with PortOne
    const portoneResult = await verifyWithPortOne(impUid);

    if (!portoneResult || portoneResult.identityVerification.status !== "VERIFIED") {
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "VERIFICATION_FAILED",
          error_message: "본인인증에 실패했습니다.",
        } as VerificationResponse),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const customer = portoneResult.identityVerification.verifiedCustomer!;
    const age = calculateAge(customer.birthDate);

    // Encrypt PII before storage
    const encryptedName = await encryptPII(customer.name, ENCRYPTION_KEY);
    const encryptedPhone = await encryptPII(customer.phoneNumber, ENCRYPTION_KEY);
    const encryptedBirthDate = await encryptPII(customer.birthDate, ENCRYPTION_KEY);
    const encryptedGender = await encryptPII(customer.gender, ENCRYPTION_KEY);
    const encryptedCi = await encryptPII(customer.ci, ENCRYPTION_KEY);

    // Store encrypted PII in identity_verifications table
    const { error: insertError } = await supabase
      .from("identity_verifications")
      .upsert({
        id: user.id,
        real_name_encrypted: encryptedName,
        phone_encrypted: encryptedPhone,
        birth_date_encrypted: encryptedBirthDate,
        gender_encrypted: encryptedGender,
        ci_encrypted: encryptedCi,
        carrier: customer.carrier,
        is_foreigner: customer.isForeigner,
        identity_imp_uid: impUid,
        verified_at: new Date().toISOString(),
      }, {
        onConflict: "id",
      });

    if (insertError) {
      console.error("Database insert error:", insertError);
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "DATABASE_ERROR",
          error_message: "인증 정보 저장에 실패했습니다.",
        } as VerificationResponse),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Update user_profiles with verification flags only (no PII)
    const { error: updateError } = await supabase
      .from("user_profiles")
      .update({
        identity_verified: true,
        identity_verified_at: new Date().toISOString(),
        phone_verified: true,
        phone_verified_at: new Date().toISOString(),
        age_verified: age >= 14,
        age_verified_at: new Date().toISOString(),
      })
      .eq("id", user.id);

    if (updateError) {
      console.error("Profile update error:", updateError);
      // Don't fail the request, identity is already stored
    }

    // Return success with masked data only
    return new Response(
      JSON.stringify({
        success: true,
        imp_uid: impUid,
        masked_phone: maskPhoneNumber(customer.phoneNumber),
        is_adult: age >= 19,
        is_at_least_14: age >= 14,
      } as VerificationResponse),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error_code: "INTERNAL_ERROR",
        error_message: "서버 오류가 발생했습니다.",
      } as VerificationResponse),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
