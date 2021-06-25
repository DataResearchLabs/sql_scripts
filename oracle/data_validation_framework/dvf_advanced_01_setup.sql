
-- ===============================================================================================
-- Filename:          dvf_advanced_01_setup.sql
-- Description:       Data Validation Framework - Setup Two "Temp" Tables
-- Platform:          Oracle
-- Author:            DataResearchLabs
-- GitHub:            https://github.com/DataResearchLabs/sql_scripts
-- YouTube Tutorials: https://www.youtube.com/channel/UCQciXv3xaBykeUFc04GxSXA
--------------------------------------------------------------------------------------------------
-- This SQL script is run one time prior to the ongoing regular running of the 
-- "regression_framework_script.sql".  
-- Run this SQL *one time* to add the "TEST_CASE_RESULTS" and "TEST_CASE_CONFIG" tables to the 
-- database in which you are running tests.  These tables contain the test results and any 
-- configuration values your test cases might need.
-- Unfortunately Oracle differs from all the other platforms in that prior to version 19, there 
-- were no private/local/on-the-fly temporary tables that can just be easily spun up within a 
-- script and then discarded.  Thus, we will just add two permanent tables one time and grant 
-- the user running the script read and write permissions to that table.
-- ===============================================================================================



-- 1: Drop Tables if Exist
--------------------------
/* -- Highlight and manually run the line below **if** it already exists.
	DROP TABLE demo_hr.test_case_results;
	DROP TABLE demo_hr.test_case_config;   
*/


-- 2: Add Table Test_Case_Results
---------------------------------
CREATE TABLE demo_hr.test_case_results (       /* <<<<<<<<<<<<<<<<<  Change Schema and Table name here */
  tst_id      VARCHAR2(5)
, tst_descr   VARCHAR2(255)
, START_TM    TIMESTAMP      DEFAULT SYSTIMESTAMP
, exec_tm     VARCHAR2(15)
, status      VARCHAR2(5)
, rej_dtls    VARCHAR2(1024)
, lookup_sql  VARCHAR(1024)
);
COMMIT;



-- 3. Add Table Test_Case_Config
CREATE TABLE demo_hr.test_case_config (       /* <<<<<<<<<<<<<<<<<  change schema and table name here */
  prop_nm     VARCHAR2(99)
, prop_val    VARCHAR2(255)
);
COMMIT;



