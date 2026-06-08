-- Feed query performance indexes for master_profiles
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_master_profiles_status_verified_active
  ON master_profiles (status, "isVerified", "isActive");

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_master_profiles_lat_lng
  ON master_profiles (lat, lng);
