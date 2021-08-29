-- SCHEMA: demo_hr

-- DROP SCHEMA demo_hr;

CREATE SCHEMA demo_hr
    AUTHORIZATION postgres;

COMMENT ON SCHEMA public
    IS 'demo_hr schema for testing out data validation scripts';

GRANT ALL ON SCHEMA demo_hr TO PUBLIC;

GRANT ALL ON SCHEMA demo_hr TO postgres;
