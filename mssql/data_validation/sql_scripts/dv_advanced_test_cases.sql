-- ===============================================================================================
-- Filename:          dv_advanced_test_cases.sql
-- Description:       Data Validation Sripts - Verification Check Examples
-- Platform:          SQL Server
-- Author:            DataResearchLabs
-- GitHub:            https://github.com/DataResearchLabs/sql_scripts
-- YouTube Tutorials: https://www.youtube.com/channel/UCQciXv3xaBykeUFc04GxSXA
-- ------------------------------------------------------------------------------------------------
-- This SQL script lays out a comprehensive set of example data validation checks.
-- It also organizes them as a table-driven regression testing framework which outputs a concise
-- report containing all test case details as well as any fail details (expected vs. actual values,
-- sql to lookup the error data, etc.).
-- The system under test consists of a database or schema, its tables and columns and all data.
-- The Test Scenario is a daily run to identify data that violates business rules.
-- The script runs one test after another sequentially, logging results and details
-- surrounding any failures to a "temp" table [TEST_CASE_RESULTS] that you should
-- have generated with a one-time run of the prior script.
-- The goal of the script is to cast a wide net that runs at least daily, if not
-- after each change as a regression test to spot business rule or logic violations
-- in the data, as close to the point of origin (change by Dev, or DBA, or something)
-- similar).
-- ===============================================================================================

-- ---------------------
-- Rule Set Definitions:
-- ---------------------
-- RS-1 = Rule Set #1: "Row Counts" - Exact count, partial set counts, relative counts to other tables, and recent count past "n" days
-- RS-2 = Rule Set #2: "Keys" - UKey dups, FKey children orphaned, FKeys parents are childless
-- RS-3 = Rule Set #3: "Heuristic Rates" - Column null rate thresholds, and column value frequency rates
-- RS-4 = Rule Set #4: "Numeric Values" - Field checks < max threshold, or > min threshold, or compare column values same table, or run some math checks
-- RS-5 = Rule Set #5: "Date Values" - Field checks < max threshold, or > mnin must be in list of possible values, or compare column values same table
-- RS-6 = Rule Set #6: "Text Values" - Field checks like must be upper case, or match regular expression, or be < max threshold value, or must be in list of possible values, or compare column values same table
-- RS-7 = Rule Set #7: "Regular Expressions" - Regular expressions offer an almost limitless number of data validation checks against text fields
-- RS-8 = Rule Set #8: "Diff Checks" - Monitor schemas and reference table or metadata contents with these tests
-- RS-9 = Rule Set #9: "Defect Regression" - When possible, write specific and separate covering tests for defects so they stand out as separate test results and are clearly regression tested every run

-- --------------
-- Best Practices
-- --------------
-- "Test Case Names" - Best Practice = TableName + RuleSetNumber/Name + Test Case name...that way sort on name and group together
-- "Skip" - Trick using SKIP instead of P or FAIL in cases where you know the test case should be skipped (no data to test, known issue, etc.)
-- "Warn" - Trick using WARN instead of P or FAIL in cases where a full on FAIL is not warranted, but you still want to track warnings
-- "Limit To Recent" - Performance trick to run script daily, *and* only analyze data for the past day (that which changed since last run)
-- "Ignore Bad Rows" - After a row fails, and a defect is written, ignore it by tacking on a WHERE clause to omit specific records by PKey value
-- "Table Scan" - Performance trick to combine many Rule Set #4 verifications into single pass table scan for performance against large tables
-- "Config Tables" - Trick using config table to manage test case parameters; demonstrated at the top of this script

-- -----------------------
-- Putting It All Together
-- -----------------------
-- Snippets Only: The SQL fundamentals only, for quick copy-paste and for GitHub documentation, and for YouTube training videos
-- Basic Script:  Simple framework that prints output to stdout (screen)
-- Advanced Script: Table-output framework (this script you are reading now)


-- ===============================================================================================
-- IMPORTANT
-- ===============================================================================================
USE Demo_HR;

-- ===============================================================================================
-- CONFIGURE TEST RUN
-- ===============================================================================================
IF OBJECT_ID('tempdb..#test_case_config') IS NOT NULL
	DROP TABLE #test_case_config
GO

CREATE TABLE #test_case_config (
  prop_nm     VARCHAR(99)
, prop_val    VARCHAR(255)
);

INSERT INTO #test_case_config VALUES('NumberDaysLookBack','100');
INSERT INTO #test_case_config VALUES('MaxNbrRowsRtn','5');



-- ===============================================================================================
-- EXECUTE TEST CASES 
-- ===============================================================================================
IF OBJECT_ID('tempdb..#test_case_results') IS NOT NULL
	DROP TABLE #test_case_results
GO

CREATE TABLE #test_case_results (
  tst_id      VARCHAR(5)
, tst_descr   VARCHAR(255)
, START_TM    DATETIME      DEFAULT GETDATE()
, exec_tm     VARCHAR(15)
, status      VARCHAR(5)
, rej_dtls    VARCHAR(1024)
, lookup_sql  VARCHAR(1024)
);


-- -----------------------------------------------------------------------------------------------
-- RULE SET #1: ROW COUNTS
-- -----------------------------------------------------------------------------------------------

-- T001 ------------------------------------------------------------------------------------------
WITH cfg  -- Config parameters 
AS (
	SELECT 'T001' AS tst_id 
	     , '"RS-1 Row Counts" #1 - Verify FullRowCount() = 25 at table [countries]' AS tst_descr
)
, dut -- Data Under Test
AS (
	SELECT COUNT(*) AS row_count 
	FROM demo_hr..countries
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT CASE WHEN row_count <> 25 THEN 'REJ: Incorrect row count|exp=25|act=' + CAST(row_count AS VARCHAR(10))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT COUNT(*) FROM demo_hr..countries' AS lookup_sql
	FROM dut
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP(SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 



-- T002 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify 'Partial' Table Row Counts"
WITH cfg  -- Config parameters 
AS (
	SELECT 'T002' AS tst_id 
	     , '"RS-1 Row Counts" #2 - Verify PartialRowCount() = 8 where [region_id] = 1 (Europe) in table [countries]' AS tst_descr
)
, dut -- Data Under Test
AS (
	SELECT COUNT(*) AS row_count 
	FROM demo_hr..countries
	WHERE region_id = 1
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT CASE WHEN row_count <> 8 THEN 'REJ: Table [countries] count where Region_ID=1 must be 8|'
	                 + 'exp=8' 
	                 + '|act=' + CAST(row_count AS VARCHAR(5))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT COUNT(*) FROM demo_hr..countries WHERE region_id = 1' AS lookup_sql
	FROM dut
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 



-- T003 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify 'Relative' Table Row Counts (vs. other tables)"
WITH cfg  -- Config parameters 
AS (
	SELECT 'T003' AS tst_id 
	     , '"RS-1 Row Counts" #3 - Verify RelativeRowCount() table [countries] row count >= 5x table [regions] row count' AS tst_descr
)
, dut -- Data Under Test
AS (
	SELECT (SELECT COUNT(*) AS row_count FROM demo_hr..countries) AS countries_count 
	     , (SELECT COUNT(*) AS row_count FROM demo_hr..regions)   AS regions_count
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT CASE WHEN countries_count < 5 * regions_count THEN 'REJ: Table [countries] row count must be >= 5x [regions] row count|'
	                 + 'exp=' + CAST(regions_count * 5 AS VARCHAR(5)) 
	                 + '|act=' + CAST(countries_count AS VARCHAR(5))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT COUNT(*) FROM demo_hr..countries;SELECT COUNT(*) FROM demo_hr..regions;' AS lookup_sql
	FROM dut
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T004 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify 'Recent' Table Row Counts"
WITH cfg  -- Config parameters 
AS (
	SELECT 'T004' AS tst_id 
	     , '"RS-1 Row Counts" #4 - Verify RecentRowCount() >= 5 in table [countries] where [date_last_updated] in past '
	       + (SELECT prop_val FROM #test_case_config WHERE prop_nm = 'NumberDaysLookBack') + ' days' AS tst_descr
)
, dut -- Data Under Test
AS (
	SELECT COUNT(*) AS row_count 
	FROM demo_hr..countries
	WHERE date_last_updated >= GETDATE() - (SELECT CAST(prop_val AS INT) FROM #test_case_config WHERE prop_nm = 'NumberDaysLookBack')
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT CASE WHEN row_count < 5 THEN 'REJ: Table [countries] count in past ' 
	                                   + (SELECT prop_val FROM #test_case_config WHERE prop_nm = 'NumberDaysLookBack') + ' days is too low|'
	
	                 + 'exp>=5' 
	                 + '|act=' + CAST(row_count AS VARCHAR(5))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT COUNT(*) FROM demo_hr..countries WHERE date_last_updated >= GETDATE() - ' 
	       + (SELECT prop_val FROM #test_case_config WHERE prop_nm = 'NumberDaysLookBack') AS lookup_sql
	FROM dut
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')	
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 



-- -----------------------------------------------------------------------------------------------
-- RULE SET #2: KEYS
-- -----------------------------------------------------------------------------------------------

-- T005 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No Dups in Unique Keys (Ukeys)"

WITH cfg -- Config Variables 
AS (
	SELECT 'T005' AS tst_id 
	     , '"RS-2 Keys" #1 - Verify UkeyHasNoDups() for UKey [country_name] in table [countries]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT country_name        -- PKey/UKey fields 
	     , COUNT(*) AS match_count 
	FROM demo_hr..countries          -- PKey/UKey fields 
	GROUP BY country_name 
	HAVING COUNT(*) > 1
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT CASE WHEN COUNT(*) > 0 THEN 'REJ: Duplicates exist by UKey|exp=0|act=' + CAST(COUNT(*) AS VARCHAR(10))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT country_name, COUNT(*) FROM demo_hr..countries GROUP BY country_name HAVING COUNT(*) > 1' AS lookup_sql
	FROM dut
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T006 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Foreign Key Children are not Orphans"

WITH cfg -- Config Variables 
AS (
	SELECT 'T006' AS tst_id 
	     , '"RS-2 Keys" #2 - Verify FKeyChildNotOrphans() at FKey-Child [region_id] in table [countries]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT DISTINCT c.region_id AS child_id, p.region_id AS parent_id
	FROM      demo_hr..countries c 
	LEFT JOIN demo_hr..regions   p  ON p.region_id = c.region_id
	WHERE p.region_id IS NULL
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT CASE WHEN parent_id IS NULL THEN 'REJ: Orphaned region_id=' + CAST(child_id AS VARCHAR(5)) + '|exp=Exists In Tbl Regions|act=Does Not Exist'
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..regions WHERE region_id=' + CAST(child_id AS VARCHAR(5)) AS lookup_sql
	FROM dut
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn') 
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T007 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Foreign Key Parents are not Childless Leaf Nodes"

WITH cfg -- Config Variables 
AS (
	SELECT 'T007' AS tst_id 
	     , '"RS-2 Keys" #3 - Verify FKeyParentHasChildren() at FKey-Parent [country_id] in table [countries]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT DISTINCT c.country_id AS child_id, p.country_id AS parent_id
	FROM      demo_hr..countries p 
	LEFT JOIN demo_hr..locations c  ON p.country_id = c.country_id
	WHERE c.country_id IS NULL
	  AND p.country_id IN('IT','JP','US','CA','CN','IN','AU','SG','UK','DE','CH','NL','MX')
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT CASE WHEN child_id IS NULL THEN 'REJ: Childless (leaf node) region_id=' + CAST(parent_id AS VARCHAR(5)) + '|exp=Exists In Tbl countries|act=Does Not Exist'
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..countries WHERE region_id=' + CAST(parent_id AS VARCHAR(5)) AS lookup_sql
	FROM dut
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn') 
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- -----------------------------------------------------------------------------------------------
-- RULE SET #3: HEURISTICS - RATES AT WHICH NULLS OR OTHER VALUES OCCUR RELATIVE TO THRESHOLDS
-- -----------------------------------------------------------------------------------------------

-- T008 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Column Null Rate Thresholds"

WITH cfg -- Config Variables 
AS (
	SELECT 'T008' AS tst_id 
	     , '"RS-3 Heuristics" #1 - Verify NullRateThresholds() for specific columns (eg: columnX is NULL for < 5% of the data ) in table [countries]' AS tst_descr
)
, dut -- data under test
AS (
	SELECT CAST(SUM(CASE WHEN department_name IS NULL THEN 1 ELSE 0 END) AS FLOAT) / CAST(COUNT(*) AS FLOAT) AS nr_dept_nm
         , CAST(SUM(CASE WHEN manager_id      IS NULL THEN 1 ELSE 0 END) AS FLOAT) / CAST(COUNT(*) AS FLOAT) AS nr_mgr_id
         , CAST(SUM(CASE WHEN url             IS NULL THEN 1 ELSE 0 END) AS FLOAT) / CAST(COUNT(*) AS FLOAT) AS nr_url
	FROM demo_hr..departments
)
, bll -- business logic layer: apply heuristics...what constitutes a pass or a fail?
AS (
	SELECT CASE WHEN nr_dept_nm > 0.0000 then 'REJ-01: Null rate too high at department_name|exp=0.0000|act=' + CAST(nr_dept_nm AS VARCHAR(8))
                WHEN nr_mgr_id  > 0.6500 then 'REJ-02: Null rate too high at manager_id|exp<=0.6500|act=' + CAST(nr_mgr_id AS VARCHAR(8))
                WHEN nr_url     > 0.8000 then 'REJ-03: Null rate too high at url|exp<=0.8000|act=' + CAST(nr_url AS VARCHAR(8))
                ELSE 'allgood'
	       END AS rej_dtls
	     ,  'Too complex. Highight and run the "dut" section of test query to lookup/confirm.' AS lookup_sql
	FROM dut
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 



-- T009 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Column Value Frequency Thresholds"

WITH cfg -- Config Variables 
AS (
	SELECT 'T009' AS tst_id 
	     , '"RS-3 Heuristics" #2 - Verify ValueFrequencyThresholds()" for [region_id] values (eg: value=1 for 28% to 36% of rows) in table [countries]' AS tst_descr
)
, dut -- data under test
AS (
	SELECT region_id
	, CAST(freq AS FLOAT) / CAST(den AS FLOAT) AS freq_rt
	FROM (
	    SELECT region_id, COUNT(*) AS freq
	    , (SELECT COUNT(*) FROM demo_hr..countries) AS den
        FROM demo_hr..countries
        GROUP BY region_id
    ) t
)
, bll -- business logic layer: apply heuristics...what constitutes a pass or a fail?
AS (
	SELECT CASE WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.28 AND 0.36 then 'REJ-01: Frequency occurrence of region_id=1 is outside threshold|exp=0.28 thru 0.36|act=' + CAST(freq_rt AS VARCHAR(8))
                WHEN region_id = 2  AND freq_rt NOT BETWEEN 0.16 AND 0.24 then 'REJ-02: Frequency occurrence of region_id=2 is outside threshold|exp=0.16 thru 0.24|act=' + CAST(freq_rt AS VARCHAR(8))
                WHEN region_id = 3  AND freq_rt NOT BETWEEN 0.20 AND 0.28 then 'REJ-03: Frequency occurrence of region_id=3 is outside threshold|exp=0.20 thru 0.28|act=' + CAST(freq_rt AS VARCHAR(8))
                WHEN region_id = 4  AND freq_rt NOT BETWEEN 0.20 AND 0.28 then 'REJ-04: Frequency occurrence of region_id=4 is outside threshold|exp=0.20 thru 0.28|act=' + CAST(freq_rt AS VARCHAR(8))
                ELSE 'allgood'
	       END AS rej_dtls
	     ,  'Too complex. Highight and run the "dut" section of test query to lookup/confirm.' AS lookup_sql
	FROM dut
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- -----------------------------------------------------------------------------------------------
-- RULE SET #4: NUMERIC VALUES
-- -----------------------------------------------------------------------------------------------

-- T010 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No Nulls in Numeric Column"

WITH cfg -- Config Variables 
AS (
	SELECT 'T010' AS tst_id 
	     , '"RS-4 Numeric" #1 - Verify NoNulls() at [region_id] in table [countries]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN region_id IS NULL  THEN 'REJ: No nulls allowed at field region_id|exp=NoNulls|act=Null'
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..countries WHERE country_id=' + CAST(country_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..countries
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T011 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Numeric Values Are Not Negative"

WITH cfg -- Config Variables 
AS (
	SELECT 'T011' AS tst_id 
	     , '"RS-4 Numeric" #2 - Verify NotNegative() where [region_id] >= 0 in table [countries]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN region_id < 0
                THEN 'REJ-01: Verify region_id is not negative|exp>=0|act=' + CAST(region_id AS VARCHAR(10))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..countries WHERE country_id=' + CAST(country_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..countries
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T012 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Numeric Boundaries (e.g.: price between $100 and $150)"

WITH cfg -- Config Variables 
AS (
	SELECT 'T012' AS tst_id 
	     , '"RS-4 Numeric" #3 - Verify NumericRange() where [employee_id] between 100 and 999 in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
    SELECT CASE WHEN employee_id < 100   THEN 'REJ-01: Verify employee_id > 99|exp>99|act=' + CAST(employee_id AS VARCHAR(10))
	            WHEN employee_id > 999   THEN 'REJ-02: Verify employee_id < 1000|exp<1000|act=' + CAST(employee_id AS VARCHAR(10))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..employees GROUP BY employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 



-- T013 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Numeric Values In List of Valid Values"

WITH cfg -- Config Variables 
AS (
	SELECT 'T013' AS tst_id 
	     , '"RS-4 Numeric" #4 - Verify InValueList() where [region_id] is in list (1,2,3,4) at table [countries]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN region_id NOT IN(1,2,3,4)
                THEN 'REJ-01: Verify region_id in domain list (1,2,3,4) of possible values|exp=1,2,3,4|act=' + CAST(region_id AS VARCHAR(3))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..countries WHERE country_id=' + CAST(country_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..countries
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T014 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Numeric Values In List of Valid Values"

WITH cfg -- Config Variables 
AS (
	SELECT 'T014' AS tst_id 
	     , '"RS-4 Numeric" #5 - Verify NotInValueList() where [region_id] is not in list (97,98,99) at table [countries]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN region_id IN(97,98,99)
                THEN 'REJ-01: Verify region_id not in domain list (97,98,99) of possible values|exp<>97,98,99|act=' + CAST(region_id AS VARCHAR(3))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..countries WHERE country_id=' + CAST(country_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..countries
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T015 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Numeric Value Multi-Field Compare"

WITH cfg -- Config Variables 
AS (
	SELECT 'T015' AS tst_id 
	     , '"RS-4 Numeric" #6 - Verify MultiFieldCompare() where [salary] x [commission_pct] <= $10,000 cap in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
    SELECT CASE WHEN salary * commission_pct > 10000
                THEN 'REJ-01: Verify salary x commission_pct <= $10,000|exp<10,000|act=' + CAST(salary * commission_pct AS VARCHAR(15))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- -----------------------------------------------------------------------------------------------
-- RULE SET #5: DATE VALUES
-- -----------------------------------------------------------------------------------------------

-- T016 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No Nulls in Date Column"

WITH cfg -- Config Variables 
AS (
	SELECT 'T016' AS tst_id 
	     , '"RS-5 Dates" #1 - Verify NoNulls() where [date_last_updated] has no nulls in table [countries]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN date_last_updated IS NULL  THEN 'REJ: No nulls allowed at field date_last_updated|exp=NoNulls|act=Null'
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..countries WHERE country_id=' + CAST(country_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..countries
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T017 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Date is not in the Future"

WITH cfg -- Config Variables 
AS (
	SELECT 'T017' AS tst_id 
	     , '"RS-5 Dates" #2 - Verify DateRange() where [date_last_updated] is not in the future nor too "old" at table [countries]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN date_last_updated > GETDATE()    THEN 'REJ-01: Field date_last_updated cannot be in the future|exp<=' + CAST(GETDATE() AS VARCHAR(20)) + '|act=' + CAST(date_last_updated AS VARCHAR(20))
	            WHEN date_last_updated < '01/01/2021' THEN 'REJ-02: Field date_last_updated cannot be too old|exp>=1/1/2021|act=' + CAST(date_last_updated AS VARCHAR(20))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT date_last_updated FROM demo_hr..countries WHERE country_id=''' + country_id + '''' AS lookup_sql
	FROM demo_hr..countries
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 



-- T018 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Date has no time part (time = 00:00:00) at table [employees]"

WITH cfg -- Config Variables 
AS (
	SELECT 'T018' AS tst_id 
	     , '"RS-5 Dates" #3 - Verify NoTimePart() where [hire_date] has no time part (is "00:00:00") in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN CONVERT(VARCHAR(8), hire_date, 108) <> '00:00:00' THEN 'REJ-01: Field hire_date cannot have a time part|exp=00:00:00|act=' + CONVERT(VARCHAR(8), hire_date, 108)
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT hire_date FROM demo_hr..employees WHERE employee_id=''' + CAST(employee_id AS VARCHAR(10)) + '''' AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T019 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Date has time part (time <> 00:00:00) at table [test_case_results]"

WITH cfg -- Config Variables 
AS (
	SELECT 'T019' AS tst_id 
	     , '"RS-5 Dates" #4 - Verify HasTimePart() where [hire_date] has time part (is not "00:00:00") at table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN CONVERT(VARCHAR(8), start_tm, 108) = '00:00:00' THEN 'REJ-01: Field start_tm must have a time part|exp<>00:00:00|act=' + CONVERT(VARCHAR(8), start_tm, 108)
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT start_tm FROM #test_case_results WHERE tst_id=''' + tst_id + '''' AS lookup_sql
	FROM #test_case_results
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T020 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Date Values Multi-Field Compare"

WITH cfg -- Config Variables 
AS (
	SELECT 'T020' AS tst_id 
	     , '"RS-5 Dates" #5 - Verify MultiFieldCompare() where [start_date] must be < [end_date] in table [job_history]' AS tst_descr
)
, dut -- Data Under Test 
AS (
    SELECT CASE WHEN start_date >= end_date
                THEN 'REJ-01: Verify start_date < end_date|exp=true|act=false'
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..job_history WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..job_history
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 



-- -----------------------------------------------------------------------------------------------
-- RULE SET #6: TEXT VALUES
-- -----------------------------------------------------------------------------------------------

-- T021 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No Nulls in Text Column"

WITH cfg -- Config Variables 
AS (
	SELECT 'T021' AS tst_id 
	     , '"RS-6 Text" #01 - Verify NoNulls() where [country_name] has no nulls in table [countries]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN country_name IS NULL  THEN 'REJ: No nulls allowed at field country_name|exp=NoNulls|act=Null'
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..countries WHERE country_id=' + CAST(country_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..countries
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T022 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No Null Strings in Text Column"

WITH cfg -- Config Variables 
AS (
	SELECT 'T022' AS tst_id 
	     , '"RS-6 Text" #02 - Verify NoNullStrings() where space (Oracle does not support "" nullstring) in [country_name] at table [countries]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN country_name = ''  THEN 'REJ: No null strings (spaces) allowed at field country_name|exp=NoNullStrings|act=NullString'
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..countries WHERE country_id=' + CAST(country_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..countries
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T023 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Text Values have no leading or trailing spaces"

WITH cfg -- Config Variables 
AS (
	SELECT 'T023' AS tst_id 
	     , '"RS-6 Text" #03 - Verify NoLeadTrailSpaces() at [country_name] in table [countries]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN country_name LIKE ' %'  THEN 'REJ-02: Verify no leading space at country_name|exp=noLeadSpace|act=''' + country_name +''''
				WHEN country_name LIKE '% '  THEN 'REJ-03: Verify no trailing space at country_name|exp=noTrailingSpace|act=''' + country_name +''''
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..countries WHERE country_id=' + CAST(country_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..countries
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T024 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Column Values In List of Valid Values"

WITH cfg -- Config Variables 
AS (
	SELECT 'T024' AS tst_id 
	     , '"RS-6 Text" #04 - Verify InValueList() where [job_id] is in list of valid values for table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN job_id NOT IN('ST_MAN','ST_CLERK','SH_CLERK','SA_REP','SA_MAN','PU_CLERK','PR_REP','MK_REP','MK_MAN','IT_PROG'
                                  ,'HR_REP','FI_MGR','FI_ACCOUNT','AD_VP','AD_PRES','AD_ASST','AC_MGR','AC_ACCOUNT','PU_MAN')
                THEN 'REJ-01: Verify job_id in domain list of possible values|exp=1of18|act=' + JOB_ID
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..employees GROUP BY employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 



-- T025 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Column Values In List of Valid Values"

WITH cfg -- Config Variables 
AS (
	SELECT 'T025' AS tst_id 
	     , '"RS-6 Text" #05 - Verify NotInValueList() where [job_id] not in list of invalid values at table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN job_id IN('CEO','CFO','COO','CIO','POTUS')
                THEN 'REJ-01: Verify job_id not in domain list of excluded values|exp<>1of5|act=' + job_id
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..employees GROUP BY employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T026 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Cross Field Comparisons"

WITH cfg -- Config Variables 
AS (
	SELECT 'T026' AS tst_id 
	     , '"RS-6 Text" #06 - Verify MultiFieldCompare() where [email] = first letter of [first_name] + [last_name] in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN email <> SUBSTRING(UPPER(SUBSTRING(first_name, 1, 1) + last_name), 1, 8) THEN 'REJ-01: Field email <> first char of first_name + last_name|exp=' 
	                          + SUBSTRING(UPPER(SUBSTRING(first_name, 1, 1) + last_name), 1, 8) + '|act=' + email
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT email, first_name, last_name FROM demo_hr..employees WHERE employee_id=''' + cast(employee_id AS VARCHAR(10)) + '''' AS lookup_sql
	FROM demo_hr..employees
	WHERE email NOT IN('DRAPHEAL', 'JAMRLOW', 'JMURMAN', 'LDEHAAN', 'JRUSSEL', 'TJOLSON')  
	               -- DRAPHAEL vs DRAPHEAL, JMARLOW vs JAMRLOW, JMURMAN vs JURMAN, LDE HAAN VS LDEHAAN, JRUSSELL vs JRUSSEL, TOLSON vs TJOLSON 
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 



-- T027 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Column Text Value Length"

WITH cfg -- Config Variables 
AS (
	SELECT 'T027' AS tst_id 
	     , '"RS-6 Text" #07 - Verify TextLength() where [phone_number] length is 12 or 18 characters in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN LEN(phone_number) NOT IN(12,18)  THEN 'REJ-01: Verify phone_number length is allowed|exp=12,18|act=' + CAST(LEN(phone_number) AS VARCHAR(6))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, phone_number, LENGTH(phone_number) FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T028 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Column Values all Upper or Lower Case"

WITH cfg -- Config Variables 
AS (
	SELECT 'T028' AS tst_id 
	     , '"RS-6 Text" #08 - Verify UpperLowerCaseChars() where [lastname] has all LCase after first character and [job_id] is all UCase in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN job_id COLLATE SQL_Latin1_General_CP1_CS_AS <> UPPER(job_id)             THEN 'REJ-01: Verify job_id does not contain lower case characters|exp=ucase|act=' + job_id
	            WHEN SUBSTRING(last_name COLLATE SQL_Latin1_General_CP1_CS_AS, 2, 255) 
				  <> LOWER(SUBSTRING(last_name COLLATE SQL_Latin1_General_CP1_CS_AS, 2, 255)) THEN 'REJ-02: Verify last_name after first char is all lower case|exp=lcase|act=' + last_name 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T029 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Column Values all Alpha only or Numeric only, or Combination"

WITH cfg -- Config Variables 
AS (
	SELECT 'T029' AS tst_id 
	     , '"RS-6 Text" #09 - Verify AlphaNumericChars() where [employee_id] is numeric, and [lastname] is alpha in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN employee_id LIKE '%[A-Za-z]%' THEN 'REJ-01: Verify employee_id does not contain alpha characters|exp=no-alphas|act=' + CAST(employee_id AS VARCHAR(20))
                WHEN last_name LIKE '%[0-9]%'      THEN 'REJ-02: Verify last_name does not contain numeric digits|exp=no-digits|act=' + last_name 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T030 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Column Values have no quotes or single quotes"

WITH cfg -- Config Variables 
AS (
	SELECT 'T030' AS tst_id 
	     , '"RS-6 Text" #10 - Verify No_Quote_Chars() where [first_name] has no quotes or apostrophes in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN first_name LIKE '%''%'  THEN 'REJ-01: Verify first_name does not contain single quote characters|exp=none|act=' + first_name
                WHEN first_name LIKE '%"%'   THEN 'REJ-02: Verify first_name does not contain quotation characters|exp=none|act=' + first_name
                ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T031 -----------------------------------------------------------------------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No CRLFs"
WITH cfg -- Config Variables 
AS (
	SELECT 'T031' AS tst_id 
	     , '"RS-6 Text" #11 - Verify No_CRLF_Chars() where [last_name] has no Carriage Returns (CHAR-13) or Line Feeds (CHAR-10) in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN CHARINDEX(last_name, CHAR(10))  > 0 THEN 'REJ-01: Field last_name has a Line Feed (CHAR-10)|exp=none|act=at position ' 
	                                                      + CAST(CHARINDEX(last_name, CHAR(10)) AS VARCHAR(4))
	            WHEN CHARINDEX(last_name, CHAR(13))  > 0 THEN 'REJ-02: Field last_name has a Carriage Return (CHAR-13)|exp=none|act=at position ' 
				                                          + CAST(CHARINDEX(last_name, CHAR(13)) AS VARCHAR(4))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, last_name FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T032 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No Tabs"

WITH cfg -- Config Variables 
AS (
	SELECT 'T032' AS tst_id 
	     , '"RS-6 Text" #12 - Verify No_TAB_Chars() where [last_name] has no TAB characters (CHAR-9) in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN CHARINDEX(last_name, CHAR(9))   > 0 THEN 'REJ-01: Field last_name has a Tab (CHAR-9)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(9)) AS VARCHAR(4))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, last_name FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T033 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No NBSs"

WITH cfg -- Config Variables 
AS (
	SELECT 'T033' AS tst_id 
	     , '"RS-6 Text" #13 - Verify No_NBS_Chars() where [last_name] has no Non-Breaking-Spaces (CHAR-160) in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN CHARINDEX(last_name, CHAR(160)) > 0 THEN 'REJ-01: Field last_name has a Non-Breaking-Space (CHAR-160)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(160)) AS VARCHAR(4))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, last_name FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T034 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No Emdashes"

WITH cfg -- Config Variables 
AS (
	SELECT 'T034' AS tst_id 
	     , '"RS-6 Text" #14 - Verify No_EmDash_Chars() where [last_name] has an EmDash character (CHAR-151...common Microsoft Word "--" conversion causing data load issues) in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN CHARINDEX(last_name, CHAR(151)) > 0 THEN 'REJ-01: Field last_name has a Non-Breaking-Space (CHAR-151)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(151)) AS VARCHAR(4))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, last_name FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T035 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No VT, FF, or NELs"

WITH cfg -- Config Variables 
AS (
	SELECT 'T035' AS tst_id 
	     , '"RS-6 Text" #15 - Verify No_VTFFNEL_Chars() where [last_name] has Vertical Tabs (CHAR-11), Form Feeds (CHAR-12) or Next Lines (CHAR-133) in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN CHARINDEX(last_name, CHAR(11)) > 0  THEN 'REJ-01: Field last_name has a Vertical Tab (CHAR-11)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(11)) AS VARCHAR(4))
	            WHEN CHARINDEX(last_name, CHAR(12)) > 0  THEN 'REJ-02: Field last_name has a Form Feed (CHAR-12)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(12)) AS VARCHAR(4))
	            WHEN CHARINDEX(last_name, CHAR(133)) > 0 THEN 'REJ-03: Field last_name has a Next Line (CHAR-133)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(133)) AS VARCHAR(4))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, last_name FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 



-- T036 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No Periods/Dashes"

WITH cfg -- Config Variables 
AS (
	SELECT 'T036' AS tst_id 
	     , '"RS-6 Text" #16 - Verify No_PeriodDash_Chars() where [last_name] has periods or dashes in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN CHARINDEX(last_name, '.') > 0 THEN 'REJ-01: Field last_name has a period|exp=none|act=at position ' + CAST(CHARINDEX(last_name, '.') AS VARCHAR(4))
	            WHEN CHARINDEX(last_name, '0') > 0 THEN 'REJ-02: Field last_name has a dash|exp=none|act=at position ' + CAST(CHARINDEX(last_name, '-') AS VARCHAR(4))
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, last_name FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T037 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No Funky Chars ,/:()&#?;"

WITH cfg -- Config Variables 
AS (
	SELECT 'T037' AS tst_id 
	     , '"RS-6 Text" #17 - Verify NoBadChars() where [last_name] has no funky punctuation ",/:()&#?;" in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN last_name LIKE '%[,/:()&#?;]%' THEN 'REJ-01: Field last_name has a ",/:()&#?;" characters|exp=none|act=' + last_name 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, last_name FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T038 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Only Allowed Chars .0123456789"

WITH cfg -- Config Variables 
AS (
	SELECT 'T038' AS tst_id 
	     , '"RS-6 Text" #18 - Verify OnlyAllowedChars() where [phone_number] only has characters ".0123456789" in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN phone_number LIKE '%[^.0123456789]%' THEN 'REJ-01: Field phone_number can only have characters ".012345789"|exp=onlyAlloweChars|act=' + phone_number 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, phone_number FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T039 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Text Using Wildcards"

WITH cfg -- Config Variables 
AS (
	SELECT 'T039' AS tst_id 
	     , '"RS-6 Text" #19 - Verify LikeWildcards() where [phone_number] contains a ''.'' and matches valid patterns in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN phone_number NOT LIKE '%.%'          THEN 'REJ-02: Verify phone_number contains a ''.''|exp=contains-.|act=' + phone_number
                WHEN phone_number NOT LIKE '___.___.____' 
                 AND phone_number NOT LIKE '011.__.____._____%' THEN 'REJ-03: Verify phone_number like pattern "___.___.____" or "011.__.____._____"|exp=yes|act=' + phone_number
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..employees GROUP BY employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T040 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Text is a number"

WITH cfg -- Config Variables 
AS (
	SELECT 'T040' AS tst_id 
	     , '"RS-6 Text" #20 - Verify IsNumeric() where [zip5] will convert to numeric in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN zip5 LIKE '%[^0-9]%' THEN 'REJ-01: Field zip9 will not convert to a number|exp=converts to number|act=' + zip5 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, zip5 FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T041 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Text Date Format is yyyymmdd"

WITH cfg -- Config Variables 
AS (
	SELECT 'T041' AS tst_id 
	     , '"RS-6 Text" #21 - Verify IsDate("yyyymmdd") where [some_date_fmt1] has date fmt="yyyymmd" in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    some_date_fmt1,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9','')
                    > ''                                                         THEN 'REJ-01: Unexpected chars exist (numeric 0-9 only)|exp=Fmt="yyyymmdd"|act=' + some_date_fmt1
                WHEN NOT LEN(TRIM(some_date_fmt1)) = 8                           THEN 'REJ-02: Must be 8 Chars|exp=Fmt="yyyymmdd"|act=' + some_date_fmt1
                WHEN NOT SUBSTRING(some_date_fmt1,1,4) BETWEEN '1753' AND '9999' THEN 'REJ-03: Year Not Btw 1753-9999|exp=Fmt="yyyymmdd"|act=' + some_date_fmt1
                WHEN NOT SUBSTRING(some_date_fmt1,5,2) BETWEEN '01' AND '12'     THEN 'REJ-04: Month Not Btw 01-12|exp=Fmt="yyyymmdd"|act=' + some_date_fmt1
                WHEN NOT SUBSTRING(some_date_fmt1,7,2) BETWEEN '01' AND '31'     THEN 'REJ-05: Day Not Btw 01-31|exp=Fmt="yyyymmdd"|act=' + some_date_fmt1
                ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, some_date_fmt1 FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T042 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Text Date Format is mm/dd/yyyy"

WITH cfg -- Config Variables 
AS (
	SELECT 'T042' AS tst_id 
	     , '"RS-6 Text" #22 - Verify IsDate("mm/dd/yyyy") where [some_date_fmt2] has date fmt="mm/dd/yyyy" in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                     some_date_fmt2,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'/','')
                     > ''                                                       THEN 'REJ-01: Unexpected Chars Exist|exp=Fmt="mm/dd/yyyy"|act=' + some_date_fmt2
               WHEN NOT LEN(TRIM(some_date_fmt2)) = 10                          THEN 'REJ-02: Must be 10 Chars|exp=Fmt="mm/dd/yyyy"|act=' + some_date_fmt2
               WHEN NOT SUBSTRING(some_date_fmt2,7,4) BETWEEN '1753' AND '9999' THEN 'REJ-03: Year Not Btw 1753-9999|exp=Fmt="mm/dd/yyyy"|act=' + some_date_fmt2
               WHEN NOT SUBSTRING(some_date_fmt2,1,2) BETWEEN '01' AND '12'     THEN 'REJ-04: Month Not Btw 01-12|exp=Fmt="mm/dd/yyyy"|act=' + some_date_fmt2
               WHEN NOT SUBSTRING(some_date_fmt2,4,2) BETWEEN '01' AND '31'     THEN 'REJ-05: Day Not Btw 01-31|exp=Fmt="mm/dd/yyyy"|act=' + some_date_fmt2
               ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, some_date_fmt2 FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T043 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Text Date Format is mm/dd/yyyy"

WITH cfg -- Config Variables 
AS (
	SELECT 'T043' AS tst_id 
	     , '"RS-6 Text" #23 - Verify IsDate("mm-dd-yyyy") where [some_date_fmt3] has date fmt="mm-dd-yyyy" in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                     some_date_fmt3,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'-','')
                     > ''                                                       THEN 'REJ-01: Unexpected Chars Exist|exp=Fmt="mm-dd-yyyy"|act=' + some_date_fmt3
               WHEN NOT LEN(TRIM(some_date_fmt3)) = 10                          THEN 'REJ-02: Must be 10 Chars|exp=Fmt="mm-dd-yyyy"|act=' + some_date_fmt3
               WHEN NOT SUBSTRING(some_date_fmt3,7,4) BETWEEN '1753' AND '9999' THEN 'REJ-03: Year Not Btw 1753-9999|exp=Fmt="mm-dd-yyyy"|act=' + some_date_fmt3
               WHEN NOT SUBSTRING(some_date_fmt3,1,2) BETWEEN '01' AND '12'     THEN 'REJ-04: Month Not Btw 01-12|exp=Fmt="mm-dd-yyyy"|act=' + some_date_fmt3
               WHEN NOT SUBSTRING(some_date_fmt3,4,2) BETWEEN '01' AND '31'     THEN 'REJ-05: Day Not Btw 01-31|exp=Fmt="mm-dd-yyyy"|act=' + some_date_fmt3
               ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, some_date_fmt3 FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T044 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Text Date Format is mm/dd/yyyy"

WITH cfg -- Config Variables 
AS (
	SELECT 'T044' AS tst_id 
	     , '"RS-6 Text" #24 - Verify IsDate("yyyy-mm-dd") where [some_date_fmt4] has date fmt="yyyy-mm-dd" in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    some_date_fmt4,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'-','')
                    > ''                                                        THEN 'REJ-01: Unexpected Chars Exist|exp=Fmt="yyyy-mm-dd"|act=' + some_date_fmt4
               WHEN NOT LEN(TRIM(some_date_fmt4)) = 10                          THEN 'REJ-02: Must be 10 Chars|exp=Fmt="yyyy-mm-dd"|act=' + some_date_fmt4
               WHEN NOT SUBSTRING(some_date_fmt4,1,4) BETWEEN '1753' AND '9999' THEN 'REJ-03: Year Not Btw 1753-9999|exp=Fmt="yyyy-mm-dd"|act=' + some_date_fmt4
               WHEN NOT SUBSTRING(some_date_fmt4,6,2) BETWEEN '01' AND '12'     THEN 'REJ-04: Month Not Btw 01-12|exp=Fmt="yyyy-mm-dd"|act=' + some_date_fmt4
               WHEN NOT SUBSTRING(some_date_fmt4,9,2) BETWEEN '01' AND '31'     THEN 'REJ-05: Day Not Btw 01-31|exp=Fmt="yyyy-mm-dd"|act=' + some_date_fmt4
               ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, some_date_fmt4 FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 



-- -----------------------------------------------------------------------------------------------
-- RULE SET #7: REGULAR EXPRESSIONS
-- -----------------------------------------------------------------------------------------------
-- SQL Server does NOT have Regular Expressions built in...but it does have very similar functionality
-- built into the LIKE operator.  We'll adjust these "regex" examples accordingly.


-- T045 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp PhoneNumber"

WITH cfg -- Config Variables 
AS (
	SELECT 'T045' AS tst_id 
	     , '"RS-7 RegEx" #01 - Verify RegExp("IsPhoneNumber") where phone_number matches pattern "###-###-####" in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
    -- NOTE: Use RegEx pattern "^\+(\d+\s?)+$" for international phone numbers
    SELECT CASE WHEN phone_number NOT LIKE '[0-9][0-9][0-9][-. ][0-9][0-9][0-9][-. ][0-9][0-9][0-9][0-9]' THEN 'REJ-01: Field phone_number failed RegExpression check|exp=Like"###-###-####" where "-" could be " " or "." too|act=' + phone_number 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, phone_number FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T046 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp SSN"

WITH cfg -- Config Variables 
AS (
	SELECT 'T046' AS tst_id 
	     , '"RS-7 RegEx" #02 - Verify RegExp("IsSSN") where [fake_ssn] matches pattern "###-##-####" in table [employees]' AS tst_descr
) 
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN fake_ssn NOT LIKE '[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]' THEN 'REJ-01: Field fake_ssn failed RegExpression check|exp=Like"###-##-####"|act=' + fake_ssn 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, fake_ssn FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T047 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp Zip5"

WITH cfg -- Config Variables 
AS (
	SELECT 'T047' AS tst_id 
	     , '"RS-7 RegEx" #03 - Verify RegExp("IsZip5") where [zip5] matches pattern "#####" in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN zip5 NOT LIKE '[0-9][0-9][0-9][0-9][0-9]' THEN 'REJ-01: Field zip5 failed RegExpression check|exp=Like"#####"|act=' + zip5 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, zip5 FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T048 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp Zip5or9"

WITH cfg -- Config Variables 
AS (
	SELECT 'T048' AS tst_id 
	     , '"RS-7 RegEx" #04 - Verify RegExp("IsZip5or9") where [zip5or9] matches pattern "#####" or "#####-####" in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN zip5or9 NOT LIKE '[0-9][0-9][0-9][0-9][0-9]'
	             AND zip5or9 NOT LIKE '[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' THEN 'REJ-01: Field zip5or9 failed RegExpression check|exp=Like"#####" or "#####-####"|act=' + zip5or9 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, zip5or9 FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T049 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp Zip9"

WITH cfg -- Config Variables 
AS (
	SELECT 'T049' AS tst_id 
	     , '"RS-7 RegEx" #05 - Verify RegExp("IsZip9") where [zip9] matches pattern "#####-####" in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN zip9 NOT LIKE '[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' THEN 'REJ-01: Field zip9 failed RegExpression check|exp=Like"#####-####"|act=' + zip9 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, zip9 FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T050 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp Text and Spaces Only (for names)"

WITH cfg -- Config Variables 
AS (
	SELECT 'T050' AS tst_id 
	     , '"RS-7 RegEx" #06 - Verify RegExp("OnlyText") where [last_name] matches pattern "%[^a-zA-Z ]%" in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN last_name LIKE '%[^a-zA-Z ]%' THEN 'REJ-01: Field last_name failed RegExpression check|exp=OnlyAlphaCharsOrSpace"|act=' + last_name 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, last_name FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T051 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp is Numeric only"

WITH cfg -- Config Variables 
AS (
	SELECT 'T051' AS tst_id 
	     , '"RS-7 RegEx" #07 - Verify RegExp("OnlyNumeric") where [zip5] matches RegEx pattern "^[0-9]+$" in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN zip5 LIKE '%[^0-9.]%' THEN 'REJ-01: Field zip5 failed RegExpression check|exp=Like"^[0-9]+$"|act=' + zip5 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, zip5 FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T052 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp Leading/Trailing Whitespace"

WITH cfg -- Config Variables 
AS (
	SELECT 'T052' AS tst_id 
	     , '"RS-7 RegEx" #08 - Verify RegExp("NoLeadTrailSpaces") where [last_name] matches pattern " %" or "% " in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN last_name LIKE ' %' OR last_name LIKE '% ' THEN 'REJ-01: Field last_name failed check|exp=NoLeadingOrTrailingSpaces|act=' + last_name 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, last_name FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T053 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp No Whitespace"

WITH cfg -- Config Variables 
AS (
	SELECT 'T053' AS tst_id 
	     , '"RS-7 RegEx" #09 - Verify RegExp("NoWhitespaces") where [job_id] has no spaces/CRLFs/TABs/NBS in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN job_id LIKE '% %'
	              OR job_id LIKE '%' + CHAR(13) + '%'
				  OR job_id LIKE '%' + CHAR(10) + '%' 
				  OR job_id LIKE '%' + CHAR(9) + '%'
				  OR job_id LIKE '%' + CHAR(160) + '%' THEN 'REJ-01: Field job_id failed RegExpression check|exp=NoSpacesTabsNewLinesNBS|act=' + job_id 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, job_id FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T054 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp Only Lower Case"

WITH cfg -- Config Variables 
AS (
	SELECT 'T054' AS tst_id 
	     , '"RS-7 RegEx" #10 - Verify RegExp("OnlyLowerCase") at 3rd and 4th chars of [first_name] are Lower Case only in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN SUBSTRING(first_name COLLATE SQL_Latin1_General_CP1_CS_AS, 3, 2) <> LOWER(SUBSTRING(first_name COLLATE SQL_Latin1_General_CP1_CS_AS, 3, 2))  
	                 THEN 'REJ-01: Chars #3 and #4 for [first_name] failed check|exp=LowerCaseOnly|act=' + SUBSTRING(first_name,2,2) 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, first_name FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T055 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp Only Upper Case"

WITH cfg -- Config Variables 
AS (
	SELECT 'T055' AS tst_id 
	     , '"RS-7 RegEx" #11 - Verify RegExp("OnlyUpperCase") where [email] are Upper Case only in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN SUBSTRING(email COLLATE SQL_Latin1_General_CP1_CS_AS, 3, 2) <> UPPER(SUBSTRING(email COLLATE SQL_Latin1_General_CP1_CS_AS, 3, 2)) 
	                 THEN 'REJ-01: Field [email] failed RegExpression check|exp=UpperCaseOnly|act=' + email 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, email FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T056 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp Title Case"

WITH cfg -- Config Variables 
AS (
	SELECT 'T056' AS tst_id 
	     , '"RS-7 RegEx" #12 - Verify RegExp("TitleCase") where [first_name] upper cases first letter second name too in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN first_name COLLATE SQL_Latin1_General_CP1_CS_AS NOT LIKE '[A-Z]%'       THEN 'REJ-01: Field first_name first character not uppercase|exp=Like"[A-Z]%"|act=' + first_name 
				WHEN first_name COLLATE SQL_Latin1_General_CP1_CS_AS LIKE '[A-Z]%[^a-z]%'    THEN 'REJ-02: Field first_name characters in first word after first character not lowercase|exp=all lower case"|act=' + first_name
				WHEN first_name NOT LIKE '% %'                                               THEN 'allgood'  -- Only one word, so no space + first character to check for uppercase
	            WHEN first_name COLLATE SQL_Latin1_General_CP1_CS_AS LIKE '% [^A-Z]%'        THEN 'REJ-03: Field first_name first character after space is not uppercase|exp=IsUCASE|act=' + first_name 
	            WHEN first_name COLLATE SQL_Latin1_General_CP1_CS_AS LIKE '% [A-Z][^a-z]%'   THEN 'REJ-04: Field first_name characters after space + one letter are not lowercase|exp=IsUCASE|act=' + first_name 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, first_name FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T057 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp EmailAddress"
-- THANK YOU:  https://www.mssqltips.com/sqlservertip/6519/valid-email-address-check-with-tsql/

-- UPDATE EMPLOYEES SET email_address = lower(email) + '@nowhere.com'; 


WITH cfg -- Config Variables 
AS (
	SELECT 'T057' AS tst_id 
	     , '"RS-7 RegEx" #13 - Verify RegExp("EmailAddress") where [email_address] matches many address pattern rules in table [employees]' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN email_address IS NULL                                     THEN 'REJ-01: Field email_address is NULL'
	            WHEN email_address = ''                                        THEN 'REJ-02: Field email_address is blank'
	            WHEN email_address LIKE '%["(),:;<>\]%'                        THEN 'REJ-03: Field email_address contains bad characters ["(),:;<>\]'
	            WHEN SUBSTRING(email_address, CHARINDEX('@', email_address), len(email_address)) LIKE '%[!#$%&*+/=?^`_{|]%'
				                                                               THEN 'REJ-04: Field email_address company name after @ contains bad characters [!#$%&*+/=?^`_{|]'
				WHEN LEFT(email_address,1) LIKE '[-_.+]'                       THEN 'REJ-05: Field email_address should not start with [-_.+] characters'
				WHEN RIGHT(email_address,1) LIKE '[-_.+]'                      THEN 'REJ-06: Field email_address should not end with [-_.+] characters'
				WHEN email_address LIKE '%[%' OR email_address LIKE '%]%'      THEN 'REJ-07: Field email_address should not contain [ or ] characters'
				WHEN email_address LIKE '%@%@%'                                THEN 'REJ-08: Field email_address should not contain more than one @ character'
				WHEN email_address LIKE '[_]%@[_]%.[_]%'                       THEN 'REJ-09: Field email_address should not have leading underscores at any segment (gmail blocks)'
				ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT employee_id, email_address FROM demo_hr..employees WHERE employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T058 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify RegExp URL"

-- THANK YOU: https://www.mssqltips.com/sqlservertutorial/9116/regular-expressions-business-case-examples-with-tsql/

WITH cfg -- Config Variables 
AS (
	SELECT 'T058' AS tst_id 
	     , '"RS-7 RegEx" #14 - Verify RegExp("IsUrl") where [url] matches pattern rules in table [departments]' AS tst_descr
)
, dut -- Data Under Test 
AS ( 
	SELECT CASE WHEN url NOT LIKE'http://%' 
	             AND url NOT LIKE'https://%'                                  THEN 'REJ-01: Field url is missing "http://" and "https://"|exp=Like"http(s)://"|act=' + url 
	            WHEN url NOT LIKE '%[A-Z0-9][.][A-Z0-9]%[A-Z0-9]%'            THEN 'REJ-02: Field is not alphanumeric + "." + alphanumeric + "/" + alphanumeric|exp=aaaa.aaa|act=' + url 
              --WHEN url NOT LIKE '%[A-Z0-9][.][A-Z0-9]%[A-Z0-9][/][A-Z0-9]%' THEN 'REJ-03: Field is not alphanumeric + "." + alphanumeric + "/" + alphanumeric|exp=aaaa.aaa/aaa|act=' + url 
				ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT department_id, url FROM demo_hr..departments WHERE department_id=' + CAST(department_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..departments
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 




-- -----------------------------------------------------------------------------------------------
-- RULE SET #8: DIFF CHECKS
-- -----------------------------------------------------------------------------------------------

-- T059 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Static Ref Table Contents for [locations]"

WITH cfg -- Config Variables 
AS (
	SELECT 'T059' AS tst_id 
	     , '"RS-8 Diffs" #1 - Verify TableStructure("BySQL") by comparing snapshot in SQL code vs actual schema/structure for table [locations]' AS tst_descr
)
, expected 
AS (
	      SELECT 1 AS ord_pos, 'LOCATION_ID'    AS column_nm, 'NUMERIC(4,0)' AS data_typ, 'NOT NULL' AS nullable
	UNION SELECT 2 AS ord_pos, 'STREET_ADDRESS' AS column_nm, 'VARCHAR(40)'  AS data_typ, 'NULL'     AS nullable
	UNION SELECT 3 AS ord_pos, 'POSTAL_CODE'    AS column_nm, 'VARCHAR(12)'  AS data_typ, 'NULL'     AS nullable
	UNION SELECT 4 AS ord_pos, 'CITY'           AS column_nm, 'VARCHAR(30)'  AS data_typ, 'NOT NULL' AS nullable
	UNION SELECT 5 AS ord_pos, 'STATE_PROVINCE' AS column_nm, 'VARCHAR(25)'  AS data_typ, 'NULL'     AS nullable
	UNION SELECT 6 AS ord_pos, 'COUNTRY_ID'     AS column_nm, 'CHAR(2)'      AS data_typ, 'NULL'     AS nullable
)
, actual
AS (
	SELECT
	  RIGHT('000' + CAST(tut.ORDINAL_POSITION AS VARCHAR(3)), 3) AS ord_pos
	, tut.column_name                                            AS column_nm
	, tut.data_type + 
      CASE WHEN tut.data_type IN('varchar','nvarchar')    THEN '(' + CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
	       WHEN tut.data_type IN('char','nchar')          THEN '(' + CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
	       WHEN tut.data_type ='date'                     THEN '(' + CAST(tut.DATETIME_PRECISION AS VARCHAR(10)) + ')'
	       WHEN tut.data_type ='datetime'                 THEN '(' + CAST(tut.DATETIME_PRECISION AS VARCHAR(10)) + ')'
	       WHEN tut.data_type LIKE '%int%'                THEN '(' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10))  + ')'
	       WHEN tut.data_type = 'uniqueidentifier'        THEN '(16)'
	       WHEN tut.data_type = 'money'                   THEN '(' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) + ')'
	       WHEN tut.data_type = 'decimal'                 THEN '(' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) + ',' + CAST(tut.NUMERIC_SCALE AS VARCHAR(10)) + ')'
	       WHEN tut.data_type = 'numeric'                 THEN '(' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) + ',' + CAST(tut.NUMERIC_SCALE AS VARCHAR(10)) + ')'
	       WHEN tut.data_type = 'varbinary'               THEN '(' + CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
	       WHEN tut.data_type = 'xml'                     THEN '(' + CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
	       WHEN tut.data_type IN('char','nchar')          THEN '(' + CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
	       WHEN tut.CHARACTER_MAXIMUM_LENGTH IS NOT NULL  THEN '(' + CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
		   WHEN tut.DATETIME_PRECISION IS NOT NULL        THEN '(' + CAST(tut.DATETIME_PRECISION AS VARCHAR(10)) + ')'
	       WHEN tut.NUMERIC_PRECISION IS NOT NULL
		    AND tut.NUMERIC_SCALE     IS NULL             THEN '(' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) + ')'
	       WHEN tut.NUMERIC_PRECISION IS NOT NULL
		    AND tut.NUMERIC_SCALE     IS NOT NULL         THEN '(' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) + ',' + CAST(tut.NUMERIC_SCALE AS VARCHAR(10)) + ')'
		   ELSE ''
      END AS data_typ
	, CASE WHEN tut.IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END AS nullable
	FROM       INFORMATION_SCHEMA.COLUMNS  tut
	WHERE tut.TABLE_CATALOG  = 'DEMO_HR'
	  AND tut.table_name = 'LOCATIONS'
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN (SELECT COUNT(*) FROM actual) = 0 THEN 'REJ-01: Table [locations] does not exist (may be case sensistive name)|exp=exists|act=notExist' 
	            WHEN a.column_nm IS NULL               THEN 'REJ-01: Expected column is missing from actual schema (may be case sensitive name)|exp=' + e.column_nm + '|act=IsMissing' 
	            WHEN a.ord_pos <> e.ord_pos            THEN 'REJ-02: Ordinal Positions at field ' + e.column_nm + ' do not match|exp=' + CAST(e.ord_pos AS VARCHAR(3)) + '|act=' + CAST(a.ord_pos AS VARCHAR(3))
	            WHEN a.data_typ <> e.data_typ          THEN 'REJ-03: Data Types at field ' + e.column_nm + ' do not match|exp=' + e.data_typ + '|act=' + a.data_typ 
	            WHEN a.nullable <> e.nullable          THEN 'REJ-04: Nullable settings at field ' + e.column_nm + ' do not match|exp=' + e.nullable + '|act=' + a.nullable 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'N/A - Go browse to table structure from tree grid in UI' AS lookup_sql
	FROM      expected e 
	LEFT JOIN actual   a ON a.column_nm = e.column_nm
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T060 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Static Ref Table Contents for [regions]"

WITH cfg -- Config Variables 
AS (
	SELECT 'T060' AS tst_id 
	     , '"RS-8 Diffs" #2 - Verify TableData("BySQL") - Data should not change for table [regions]' AS tst_descr
)
, metadata 
AS (
	      SELECT 1 AS region_id, 'Europe' AS region_name 
	UNION SELECT 2 AS region_id, 'Americas' AS region_name
	UNION SELECT 3 AS region_id, 'Asia' AS region_name 
	UNION SELECT 4 AS region_id, 'Middle East and Africa' AS region_name 
  --ORDER BY region_id
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN r.region_id IS NULL            THEN 'REJ-01: Record is missing from metadata|exp=NotMissing|act=' + CAST(m.region_id AS VARCHAR(4)) + ' is missing' 
	            WHEN r.region_name <> m.region_name THEN 'REJ-02: Region_Name does not match|exp=' + m.region_name + '|act=' + r.region_name 
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..regions WHERE region_id=' + CAST(m.region_id AS VARCHAR(15)) AS lookup_sql
	FROM      metadata   m 
	LEFT JOIN demo_hr..regions r ON r.region_id = m.region_id
  --ORDER BY m.region_id
	
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T061 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Dynamic Ref Table Contents for [jobs] vs [jobs_snapshot]"

-- SELECT * INTO demo_hr..jobs_snapshot FROM demo_hr..jobs 

WITH cfg -- Config Variables 
AS (
	SELECT 'T061' AS tst_id 
	     , '"RS-8 Diffs" #3 - Verify TableData("By2TableCompare") - Table data should exactly match between tables [jobs] and [jobs_snapshot]' AS tst_descr
)
, non_matches
AS (
    SELECT MAX(tbl_nm) AS tbl_nm, job_id, job_title, min_salary, max_salary, COUNT(*) AS match_count_found
    FROM (
		SELECT CAST('jobs' AS VARCHAR(15)) AS tbl_nm,          job_id, job_title, min_salary, max_salary FROM demo_hr..JOBS  
		UNION ALL 
		SELECT CAST('jobs_snapshot' AS VARCHAR(15)) AS tbl_nm, job_id, job_title, min_salary, max_salary FROM demo_hr..JOBS_SNAPSHOT 
    ) comb_sets 
    GROUP BY job_id, job_title, min_salary, max_salary
    HAVING COUNT(*) < 2
)
, dut -- Data Under Test 
AS (
	SELECT 'REJ-01: Mismatch Found: tbl_nm="' + tbl_nm +'", job_id="' + job_id + '", job_title="' + job_title 
	    + '", min_salary=' + CAST(min_salary AS VARCHAR(20)) + '", max_salary=' + CAST(max_salary AS VARCHAR(20)) AS rej_dtls
	     , 'Too complex, better to go manually run the SQL for "non_matches" CTE sub-table' AS lookup_sql
	FROM      non_matches  
  --ORDER BY 1
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 



-- -----------------------------------------------------------------------------------------------
-- RULE SET #9: DEFECT REGRESSION
-- -----------------------------------------------------------------------------------------------

-- This is where you would add on SQL validations (where appropriate) that regression test defects
-- that come up over time.  Most will take the form of one of the example test cases above.




-- -----------------------------------------------------------------------------------------------
-- BEST PRACTICES: 
-- -----------------------------------------------------------------------------------------------

-- T062 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify Column Value Frequency Thresholds"

WITH cfg -- Config Variables 
AS (
	SELECT 'T062' AS tst_id 
	     , '"X#1 WarnSkip" - Verify ValueFrequencyThresholds()" for [region_id] values (eg: value=1 for 28% to 36% of rows) in table [countries]' AS tst_descr
)
, dut -- data under test
AS (
	SELECT region_id
	, CAST(freq AS FLOAT) / CAST(den AS FLOAT) AS freq_rt
	FROM (
	    SELECT region_id, COUNT(*) AS freq
	    , (SELECT COUNT(*) FROM demo_hr..countries) AS den
        FROM demo_hr..countries
        GROUP BY region_id
    ) t
)
, bll -- business logic layer: apply heuristics...what constitutes a pass or a fail?
AS (
	SELECT CASE WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.10 AND 0.50 then 'FAIL: Frequency occurrence of region_id=1 is FAR outside threshold|exp=0.28 thru 0.36|act=' + CAST(freq_rt AS VARCHAR(8))
                WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.25 AND 0.35 then 'WARN: Frequency occurrence of region_id=1 is outside threshold|exp=0.20 thru 0.28|act=' + CAST(freq_rt AS VARCHAR(8))
                ELSE 'allgood'
	       END AS rej_dtls
	     ,  'Too complex. Highight and run the "dut" section of test query to lookup/confirm.' AS lookup_sql
	FROM dut
)
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , CASE WHEN (SELECT COUNT(*) FROM bll) = 0 THEN 'SKIP'
	            WHEN (SELECT COUNT(*) FROM bll WHERE rej_dtls LIKE 'FAIL:%') > 0 THEN 'FAIL'
	            WHEN (SELECT COUNT(*) FROM bll WHERE rej_dtls LIKE 'WARN:%') > 0 THEN 'WARN'
	            ELSE 'P'
	       END AS stus
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP (SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT TOP 1 stus FROM hdr) AS stus
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
 

-- T063 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No Nulls in Numeric Column"

WITH cfg -- Config Variables 
AS (
	SELECT 'T063' AS tst_id 
	     , '"X#2 LimitToRecent" - VerVerify NoNulls() at [region_id] in table [countries] for past 30 days' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN region_id IS NULL  THEN 'REJ: No nulls allowed at field region_id|exp=NoNulls|act=Null'
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..countries WHERE country_id=' + CAST(country_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..countries
	WHERE date_last_updated >= GETDATE() - 30  -- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP(SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T064 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Verify No Nulls in Numeric Column"

WITH cfg -- Config Variables 
AS (
	SELECT 'T064' AS tst_id 
	     , '"X#3 IgnoreBadRows" - Verify NoNulls() at [region_id] in table [countries]; ignoring 3 known bad rows' AS tst_descr
)
, dut -- Data Under Test 
AS (
	SELECT CASE WHEN region_id IS NULL  THEN 'REJ: No nulls allowed at field region_id|exp=NoNulls|act=Null'
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..countries WHERE country_id=' + CAST(country_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..countries
	WHERE country_id NOT IN('BR','DK','IL')  -- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP(SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T065 ------------------------------------------------------------------------------------------
-- EXAMPLE: How to "Roll dozens of checks into a single table scan pass for best performance"

WITH cfg -- Config Variables 
AS (
	SELECT 'T065' AS tst_id 
	     , '"X#4 TableScan" - Verify dozens of checks in a single table scan pass against table [employees] for best performance' AS tst_descr
)
, dut -- Data Under Test 
AS (
    SELECT CASE WHEN employee_id < 100                                            THEN 'REJ-01: Field employee_id > 99|exp>99|act=' + CAST(employee_id AS VARCHAR(10))
	            WHEN employee_id > 999                                            THEN 'REJ-02: Field employee_id < 1000|exp<1000|act=' + CAST(employee_id AS VARCHAR(10))
	            WHEN salary * commission_pct > 10000                              THEN 'REJ-03: Fields salary x commission_pct <= $10,000|exp<10,000|act=' + CAST(salary * commission_pct AS VARCHAR(15))
				WHEN CONVERT(VARCHAR(8), hire_date, 108) <> '00:00:00'            THEN 'REJ-04: Field hire_date cannot have a time part|exp=12:00:00|act=' + CONVERT(VARCHAR(8), hire_date, 108)
                WHEN zip5 LIKE '%[^0-9]%'                                         THEN 'REJ-05: Field zip9 will not convert to a number|exp=converts to number|act=' + zip5
	            WHEN job_id IN('CEO','CFO','COO','CIO','POTUS')                   THEN 'REJ-06: Field job_id not in domain list of excluded values|exp<>1of5|act=' + job_id
	            WHEN email <> SUBSTRING(UPPER(SUBSTRING(first_name, 1, 1) 
				              + last_name), 1, 8)                                 THEN 'REJ-07: Field email <> first char of first_name + last_name|exp=' + SUBSTRING(UPPER(SUBSTRING(first_name, 1, 1) + last_name), 1, 8) + '|act=' + email
	            WHEN LEN(phone_number) NOT IN(12,18)                              THEN 'REJ-08: Field phone_number length is allowed|exp=12,18|act=' + CAST(LEN(phone_number) AS VARCHAR(6))
	            WHEN job_id COLLATE SQL_Latin1_General_CP1_CS_AS <> UPPER(job_id) THEN 'REJ-09: Field job_id does not contain lower case characters|exp=ucase|act=' + EMAIL
	            WHEN SUBSTRING(last_name COLLATE SQL_Latin1_General_CP1_CS_AS, 2, 255) <> LOWER(SUBSTRING(last_name COLLATE SQL_Latin1_General_CP1_CS_AS, 2, 255)) THEN 'REJ-10: Verify last_name after first char is all lower case|exp=lcase|act=' + last_name 
				WHEN employee_id LIKE '%[A-Za-z]%'                                THEN 'REJ-11: Field employee_id does not contain alpha characters|exp=no-alphas|act=' + CAST(employee_id AS VARCHAR(20))
                WHEN last_name LIKE '%[0-9]%'                                     THEN 'REJ-12: Field last_name does not contain numeric digits|exp=no-digits|act=' + LAST_NAME 
	            WHEN first_name LIKE '%''%'                                       THEN 'REJ-13: Field first_name does not contain single quote characters|exp=none|act=' + first_name
                WHEN first_name LIKE '%"%'                                        THEN 'REJ-14: Field first_name does not contain quotation characters|exp=none|act=' + first_name
                WHEN CHARINDEX(last_name, CHAR(10))  > 0                          THEN 'REJ-15: Field last_name has a Line Feed (CHAR-10)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(10)) AS VARCHAR(4))
	            WHEN CHARINDEX(last_name, CHAR(13))  > 0                          THEN 'REJ-16: Field last_name has a Carriage Return (CHAR-13)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(13)) AS VARCHAR(4))
	            WHEN CHARINDEX(last_name, CHAR(9))   > 0                          THEN 'REJ-17: Field last_name has a Tab (CHAR-9)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(9)) AS VARCHAR(4))
	            WHEN CHARINDEX(last_name, CHAR(160)) > 0                          THEN 'REJ-18: Field last_name has a Non-Breaking-Space (CHAR-160)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(160)) AS VARCHAR(4))
	            WHEN CHARINDEX(last_name, CHAR(151)) > 0                          THEN 'REJ-19: Field last_name has a Non-Breaking-Space (CHAR-151)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(151)) AS VARCHAR(4))
	            WHEN CHARINDEX(last_name, CHAR(11)) > 0                           THEN 'REJ-20: Field last_name has a Vertical Tab (CHAR-11)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(11)) AS VARCHAR(4))
	            WHEN CHARINDEX(last_name, CHAR(12)) > 0                           THEN 'REJ-21: Field last_name has a Form Feed (CHAR-12)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(12)) AS VARCHAR(4))
	            WHEN CHARINDEX(last_name, CHAR(133)) > 0                          THEN 'REJ-22: Field last_name has a Next Line (CHAR-133)|exp=none|act=at position ' + CAST(CHARINDEX(last_name, CHAR(133)) AS VARCHAR(4))
	            WHEN CHARINDEX(last_name, '.') > 0                                THEN 'REJ-23: Field last_name has a period|exp=none|act=at position ' + CAST(CHARINDEX(last_name, '.') AS VARCHAR(4))
	            WHEN last_name LIKE '%[,/:()&#?;]%'                               THEN 'REJ-24: Field last_name has a ",/:()&#?;" characters|exp=none|act=' + last_name 
	            WHEN phone_number LIKE '%[^.0123456789]%'                         THEN 'REJ-25: Field phone_number can only have characters ".012345789"|exp=onlyAlloweChars|act=' + phone_number 
	            WHEN phone_number NOT LIKE '%.%'                                  THEN 'REJ-26: Verify phone_number contains a ''.''|exp=contains-.|act=' + phone_number
                WHEN phone_number NOT LIKE '___.___.____' 
                 AND phone_number NOT LIKE '011.__.____._____%'                   THEN 'REJ-27: Verify phone_number like pattern "___.___.____" or "011.__.____._____"|exp=yes|act=' + phone_number
	            WHEN zip5 LIKE '%[^0-9]%'                                         THEN 'REJ-28: Field zip9 will not convert to a number|exp=converts to number|act=' + zip5 
	            WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
	                 REPLACE(REPLACE(REPLACE(some_date_fmt1,'0',''),'1','')
	                 ,'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8'
	                 ,''),'9','')  > ''                                           THEN 'REJ-29: Unexpected chars exist (numeric 0-9 only)|exp=Fmt="yyyymmdd"|act=' + some_date_fmt1
                WHEN NOT LEN(TRIM(some_date_fmt1)) = 8                            THEN 'REJ-30: Must be 8 Chars|exp=Fmt="yyyymmdd"|act=' + some_date_fmt1
                WHEN NOT SUBSTRING(some_date_fmt1,1,4) BETWEEN '1753' AND '9999'  THEN 'REJ-31: Year Not Btw 1753-9999|exp=Fmt="yyyymmdd"|act=' + some_date_fmt1
                WHEN NOT SUBSTRING(some_date_fmt1,5,2) BETWEEN '01' AND '12'      THEN 'REJ-32: Month Not Btw 01-12|exp=Fmt="yyyymmdd"|act=' + some_date_fmt1
                WHEN NOT SUBSTRING(some_date_fmt1,7,2) BETWEEN '01' AND '31'      THEN 'REJ-33: Day Not Btw 01-31|exp=Fmt="yyyymmdd"|act=' + some_date_fmt1
	            ELSE 'allgood'
	       END AS rej_dtls
	     , 'SELECT * FROM demo_hr..employees GROUP BY employee_id=' + CAST(employee_id AS VARCHAR(15)) AS lookup_sql
	FROM demo_hr..employees
    WHERE email NOT IN('DRAPHEAL', 'JAMRLOW', 'JMURMAN', 'LDEHAAN', 'JRUSSEL', 'TJOLSON')  
	               -- DRAPHAEL vs DRAPHEAL, JMARLOW vs JAMRLOW, JMURMAN vs JURMAN, LDE HAAN VS LDEHAAN, JRUSSELL vs JRUSSEL, TOLSON vs TJOLSON)
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP(SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , bll.lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 


-- T066 ------------------------------------------------------------------------------------------
-- EXAMPLE: Reference configuration settings from a temporary lookup table

WITH cfg -- Config Variables 
AS (
	SELECT 'T066' AS tst_id 
	     , '"X#5 ConfigTbl" - Reference configuration settings from a temporary lookup table' AS tst_descr
)
, dut -- Data Under Test 
AS (
    SELECT CASE WHEN row_count < 5 THEN 'FAIL'
                ELSE 'allgood'
           END AS rej_dtls
        FROM (
            SELECT COUNT(*) AS row_count 
            FROM demo_hr..countries
            WHERE date_last_updated >= GETDATE() - (SELECT CAST(prop_val AS INT) 
                                                    FROM #test_case_config 
                                                    WHERE prop_nm = 'NumberDaysLookBack')
        ) t
)
, bll -- Business Logic Layer: Apply heuristics...what constitutes a pass or a fail? 
AS (
	SELECT * FROM dut WHERE rej_dtls <> 'allgood'
)
-- >>>>>>>>>>>>>> Begin Boilerplate code
, hdr -- Header Row, always exists regardless whether fails exist or not 
AS (
	SELECT cfg.tst_id
	     , cfg.tst_descr
	     , (SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END FROM bll WHERE rej_dtls <> 'allgood') AS status
	     , '(Header)' AS rej_dtls 
	     , ' ' AS lookup_sql
	FROM cfg
)
, fdtl -- Fail Detail Rows, empty if a Pass 
AS (
	SELECT TOP(SELECT CAST(prop_val AS SMALLINT) FROM #test_case_config WHERE prop_nm='MaxNbrRowsRtn')
	       cfg.tst_id
	     , cfg.tst_descr
	     , 'FAIL' AS status
	     , bll.rej_dtls
	     , ' ' AS lookup_sql
	FROM cfg, bll
	WHERE bll.rej_dtls <> 'allgood'
)
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
SELECT * FROM hdr
UNION
SELECT * FROM fdtl
;
-- End Boilerplate code <<<<<<<<<<<<<< 







-- ===============================================================================================
-- Calculate execution times as start next test minus start of current test
-- ===============================================================================================
-- log final systimestamp to close out last test case 
INSERT INTO #test_case_results(tst_id, tst_descr, status, rej_dtls, lookup_sql)
VALUES('T999', '{ Final timestamp logged }', 'P', ' ', 'SELECT GETDATE();');


-- update all execution times 
UPDATE #test_case_results
SET exec_tm = tst.exec_tm
FROM (SELECT tst_id
           , CAST(ROUND(CAST(MAX(DATEDIFF(ms, start_tm,end_tm)) AS FLOAT) / 1000.0, 3) AS VARCHAR(12)) + ' sec' AS exec_tm
      FROM (
	    SELECT tst_id, exec_tm, start_tm
        , LEAD(start_tm) OVER(ORDER BY start_tm) end_tm
        FROM #test_case_results
      ) t1
	  GROUP BY tst_id
) tst
WHERE #test_case_results.tst_id = tst.tst_id
;




-- ===============================================================================================
-- test case results (code never changes)
-- ===============================================================================================

WITH rslts
AS (
  SELECT t.*
  , CASE WHEN status = 'FAIL' THEN 1
         WHEN status = 'WARN' THEN 2
         ELSE 3   -- 'SKIP' and 'P'
    END AS ord_lvl
  FROM #test_case_results t
)

, rslts_ord
AS (
  SELECT t.*
  , ROW_NUMBER() OVER(ORDER BY ord_lvl, tst_descr, rej_dtls) AS ord
  FROM (SELECT * 
        FROM rslts 
        ) t
)

SELECT CASE WHEN rej_dtls = '(Header)' THEN status    ELSE ' ' END AS status
     , CASE WHEN rej_dtls = '(Header)' THEN tst_id    ELSE ' ' END AS tst_id
     , CASE WHEN rej_dtls = '(Header)' THEN tst_descr ELSE ' ' END AS tst_descr
     , CASE WHEN rej_dtls = '(Header)' THEN exec_tm   ELSE ' ' END AS exec_tm
     , CASE WHEN rej_dtls = '(Header)' THEN start_tm  ELSE NULL END AS start_tm
     , SUBSTRING(rej_dtls, 1, NULLIF(CHARINDEX('|', rej_dtls) - 1, -1)) AS rej_dtls 
     , SUBSTRING(rej_dtls, CHARINDEX('|', rej_dtls) + 1, LEN(rej_dtls) - CHARINDEX('|', rej_dtls) - CHARINDEX('|', REVERSE(rej_dtls)) ) AS exp_rslt
     , REVERSE(SUBSTRING(REVERSE(rej_dtls), 0, CHARINDEX('|', REVERSE(rej_dtls)))) AS act_rslt 
     , lookup_sql
FROM rslts_ord
WHERE tst_id <> 'T999'
ORDER BY ord
;
