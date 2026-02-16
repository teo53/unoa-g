import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/agency.dart';

void main() {
  group('Agency', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 'agency-001',
          'name': '스타빛엔터테인먼트',
          'logo_url': 'https://example.com/logo.png',
          'status': 'active',
        };
        final agency = Agency.fromJson(json);

        expect(agency.id, equals('agency-001'));
        expect(agency.name, equals('스타빛엔터테인먼트'));
        expect(agency.logoUrl, equals('https://example.com/logo.png'));
        expect(agency.status, equals('active'));
      });

      test('defaults missing optional fields', () {
        final json = {
          'id': 'agency-002',
          'name': '테스트 소속사',
        };
        final agency = Agency.fromJson(json);

        expect(agency.logoUrl, isNull);
        expect(agency.status, equals('active'));
      });
    });
  });

  group('AgencyContract', () {
    Map<String, dynamic> createContractJson({
      String id = 'contract-001',
      String agencyId = 'agency-001',
      String agencyName = '스타빛엔터테인먼트',
      String? agencyLogoUrl,
      String status = 'active',
      double revenueShareRate = 0.10,
      String settlementPeriod = 'monthly',
      String? contractStartDate = '2025-01-01',
      String? contractEndDate = '2026-12-31',
      String? powerOfAttorneyUrl,
      String? notes,
      String createdAt = '2025-01-01T00:00:00.000Z',
    }) {
      return {
        'id': id,
        'agency_id': agencyId,
        'agency_name': agencyName,
        if (agencyLogoUrl != null) 'agency_logo_url': agencyLogoUrl,
        'status': status,
        'revenue_share_rate': revenueShareRate,
        'settlement_period': settlementPeriod,
        if (contractStartDate != null) 'contract_start_date': contractStartDate,
        if (contractEndDate != null) 'contract_end_date': contractEndDate,
        if (powerOfAttorneyUrl != null)
          'power_of_attorney_url': powerOfAttorneyUrl,
        if (notes != null) 'notes': notes,
        'created_at': createdAt,
      };
    }

    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = createContractJson(
          agencyLogoUrl: 'https://example.com/logo.png',
          powerOfAttorneyUrl: 'https://example.com/poa.pdf',
          notes: '계약 메모',
        );
        final contract = AgencyContract.fromJson(json);

        expect(contract.id, equals('contract-001'));
        expect(contract.agencyId, equals('agency-001'));
        expect(contract.agencyName, equals('스타빛엔터테인먼트'));
        expect(contract.agencyLogoUrl, equals('https://example.com/logo.png'));
        expect(contract.status, equals('active'));
        expect(contract.revenueShareRate, equals(0.10));
        expect(contract.settlementPeriod, equals('monthly'));
        expect(contract.contractStartDate, equals('2025-01-01'));
        expect(contract.contractEndDate, equals('2026-12-31'));
        expect(contract.hasPowerOfAttorney, isTrue);
        expect(contract.notes, equals('계약 메모'));
        expect(contract.createdAt, equals('2025-01-01T00:00:00.000Z'));
      });

      test('defaults missing optional fields', () {
        final json = {
          'id': 'c-002',
          'agency_id': 'a-002',
          'status': 'pending',
          'created_at': '2025-06-01T00:00:00.000Z',
        };
        final contract = AgencyContract.fromJson(json);

        expect(contract.agencyName, equals(''));
        expect(contract.agencyLogoUrl, isNull);
        expect(contract.revenueShareRate, equals(0.0));
        expect(contract.settlementPeriod, equals('monthly'));
        expect(contract.contractStartDate, isNull);
        expect(contract.contractEndDate, isNull);
        expect(contract.hasPowerOfAttorney, isFalse);
        expect(contract.notes, isNull);
      });
    });

    group('computed properties', () {
      test('isActive returns true for active status', () {
        final contract =
            AgencyContract.fromJson(createContractJson(status: 'active'));
        expect(contract.isActive, isTrue);
        expect(contract.isPending, isFalse);
      });

      test('isPending returns true for pending status', () {
        final contract =
            AgencyContract.fromJson(createContractJson(status: 'pending'));
        expect(contract.isPending, isTrue);
        expect(contract.isActive, isFalse);
      });

      test('statusLabel returns Korean label', () {
        expect(
          AgencyContract.fromJson(createContractJson(status: 'active'))
              .statusLabel,
          equals('활성'),
        );
        expect(
          AgencyContract.fromJson(createContractJson(status: 'pending'))
              .statusLabel,
          equals('승인 대기'),
        );
        expect(
          AgencyContract.fromJson(createContractJson(status: 'paused'))
              .statusLabel,
          equals('일시정지'),
        );
        expect(
          AgencyContract.fromJson(createContractJson(status: 'terminated'))
              .statusLabel,
          equals('해지'),
        );
        expect(
          AgencyContract.fromJson(createContractJson(status: 'unknown'))
              .statusLabel,
          equals('unknown'),
        );
      });

      test('settlementPeriodLabel returns Korean label', () {
        expect(
          AgencyContract.fromJson(
                  createContractJson(settlementPeriod: 'weekly'))
              .settlementPeriodLabel,
          equals('주간'),
        );
        expect(
          AgencyContract.fromJson(
                  createContractJson(settlementPeriod: 'biweekly'))
              .settlementPeriodLabel,
          equals('격주'),
        );
        expect(
          AgencyContract.fromJson(
                  createContractJson(settlementPeriod: 'monthly'))
              .settlementPeriodLabel,
          equals('월간'),
        );
      });

      test('contractPeriodLabel formats date range', () {
        expect(
          AgencyContract.fromJson(createContractJson(
            contractStartDate: '2025-01-01',
            contractEndDate: '2026-12-31',
          )).contractPeriodLabel,
          equals('2025-01-01 ~ 2026-12-31'),
        );
      });

      test('contractPeriodLabel shows 무기한 when no end date', () {
        final json = createContractJson(
          contractStartDate: '2025-03-01',
        );
        json.remove('contract_end_date');
        expect(
          AgencyContract.fromJson(json).contractPeriodLabel,
          equals('2025-03-01 ~ 무기한'),
        );
      });

      test('contractPeriodLabel returns - when no start date', () {
        final json = createContractJson();
        json.remove('contract_start_date');
        json.remove('contract_end_date');
        expect(
          AgencyContract.fromJson(json).contractPeriodLabel,
          equals('-'),
        );
      });

      test('settlementModeLabel for individual vs consolidated', () {
        expect(
          AgencyContract.fromJson(createContractJson()).settlementModeLabel,
          equals('개별 정산'),
        );
        expect(
          AgencyContract.fromJson(createContractJson(
            powerOfAttorneyUrl: 'https://example.com/poa.pdf',
          )).settlementModeLabel,
          equals('통합 정산 (위임장)'),
        );
      });
    });
  });

  group('AgencyInvitation', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 'inv-001',
          'agency_id': 'agency-001',
          'agency_name': '스타빛엔터테인먼트',
          'agency_logo_url': 'https://example.com/logo.png',
          'revenue_share_rate': 0.15,
          'contract_start_date': '2025-06-01',
          'contract_end_date': '2027-05-31',
          'settlement_period': 'biweekly',
          'power_of_attorney_url': 'https://example.com/poa.pdf',
          'notes': '초대 메모',
          'created_at': '2025-05-15T10:00:00.000Z',
        };
        final inv = AgencyInvitation.fromJson(json);

        expect(inv.contractId, equals('inv-001'));
        expect(inv.agencyId, equals('agency-001'));
        expect(inv.agencyName, equals('스타빛엔터테인먼트'));
        expect(inv.agencyLogoUrl, equals('https://example.com/logo.png'));
        expect(inv.revenueShareRate, equals(0.15));
        expect(inv.contractStartDate, equals('2025-06-01'));
        expect(inv.contractEndDate, equals('2027-05-31'));
        expect(inv.settlementPeriod, equals('biweekly'));
        expect(inv.hasPowerOfAttorney, isTrue);
        expect(inv.notes, equals('초대 메모'));
        expect(inv.createdAt, equals('2025-05-15T10:00:00.000Z'));
      });

      test('defaults missing optional fields', () {
        final json = {
          'id': 'inv-002',
          'agency_id': 'agency-002',
          'revenue_share_rate': 0.10,
          'created_at': '2025-06-01T00:00:00.000Z',
        };
        final inv = AgencyInvitation.fromJson(json);

        expect(inv.agencyName, equals(''));
        expect(inv.agencyLogoUrl, isNull);
        expect(inv.contractStartDate, isNull);
        expect(inv.contractEndDate, isNull);
        expect(inv.settlementPeriod, equals('monthly'));
        expect(inv.hasPowerOfAttorney, isFalse);
        expect(inv.notes, isNull);
      });
    });
  });
}
