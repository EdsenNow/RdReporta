-- ============================================================
-- RDReporta: PostGIS Extension Initialization
-- ============================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Verification
DO $$
BEGIN
    RAISE NOTICE 'PostGIS Extension initialized successfully: %', postgis_version();
END $$;
