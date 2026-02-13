-- 058: 통신판매중개자 고지 비활성화
-- 사유: 통신판매업(총매법) 포지셔닝 전환에 따라 중개자 고지 불필요
UPDATE public.compliance_disclosures
SET status = 'INACTIVE',
    notes = '통신판매업 포지셔닝 전환 (2026-02-13)',
    updated_at = now()
WHERE disclosure_type = 'INTERMEDIARY_NOTICE';
