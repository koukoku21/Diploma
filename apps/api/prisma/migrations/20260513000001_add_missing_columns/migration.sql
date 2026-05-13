-- Add missing columns to users table
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "isGuest" BOOLEAN NOT NULL DEFAULT false;

-- Add missing columns to master_profiles table
ALTER TABLE "master_profiles" ADD COLUMN IF NOT EXISTS "username" TEXT;
ALTER TABLE "master_profiles" ADD COLUMN IF NOT EXISTS "bookingSlug" TEXT;
ALTER TABLE "master_profiles" ADD COLUMN IF NOT EXISTS "isBookingLinkActive" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "master_profiles" ADD COLUMN IF NOT EXISTS "isVisible" BOOLEAN NOT NULL DEFAULT true;

-- Add unique constraints if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'master_profiles_username_key'
  ) THEN
    ALTER TABLE "master_profiles" ADD CONSTRAINT "master_profiles_username_key" UNIQUE ("username");
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'master_profiles_bookingSlug_key'
  ) THEN
    ALTER TABLE "master_profiles" ADD CONSTRAINT "master_profiles_bookingSlug_key" UNIQUE ("bookingSlug");
  END IF;
END $$;

-- Add missing columns to bookings table
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "cancelReason" TEXT;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "source" TEXT NOT NULL DEFAULT 'APP';
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "reminderSentAt" TIMESTAMP(3);
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "salonId" TEXT;
