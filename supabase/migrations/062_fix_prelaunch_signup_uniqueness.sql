-- Split prelaunch signup uniqueness by signup type.
-- Authenticated users: unique by (campaign_id, user_id)
-- Anonymous/email users: unique by (campaign_id, email)

ALTER TABLE public.funding_prelaunch_signups
  DROP CONSTRAINT IF EXISTS unique_prelaunch_signup;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_prelaunch_signup_campaign_user
  ON public.funding_prelaunch_signups (campaign_id, user_id)
  WHERE user_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_prelaunch_signup_campaign_email
  ON public.funding_prelaunch_signups (campaign_id, email)
  WHERE email IS NOT NULL;

ALTER TABLE public.funding_prelaunch_signups
  DROP CONSTRAINT IF EXISTS funding_prelaunch_signups_identity_check;

ALTER TABLE public.funding_prelaunch_signups
  ADD CONSTRAINT funding_prelaunch_signups_identity_check
  CHECK (user_id IS NOT NULL OR email IS NOT NULL);
