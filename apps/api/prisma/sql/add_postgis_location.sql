-- PostGIS: добавить колонку location в master_profiles
-- Запускать ПОСЛЕ prisma migrate dev --name init
-- Команда: psql $DATABASE_URL -f prisma/sql/add_postgis_location.sql

CREATE EXTENSION IF NOT EXISTS postgis;

ALTER TABLE master_profiles
ADD COLUMN IF NOT EXISTS location geography(Point, 4326);

CREATE INDEX IF NOT EXISTS master_profiles_location_idx
ON master_profiles USING GIST(location);

-- Заполнить location из существующих lat/lng
UPDATE master_profiles
SET location = ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
WHERE location IS NULL AND lat IS NOT NULL AND lng IS NOT NULL;
