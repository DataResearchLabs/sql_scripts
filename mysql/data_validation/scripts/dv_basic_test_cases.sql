-- ===============================================================================================
-- Filename:          dv_basic_test_cases.sql
-- Description:       Data Validation Basic Script - Verification Check Examples
-- Platform:          MySQL
-- Author:            DataResearchLabs
-- GitHub:            https://github.com/DataResearchLabs/sql_scripts
-- ------------------------------------------------------------------------------------------------
-- This SQL snippet is a simple, low-tech example of running data validation checks.
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

-- -----------------------------------------------------------------------------------------------
-- INITIALIZE
-- -----------------------------------------------------------------------------------------------
USE demo_hr;


-- -----------------------------------------------------------------------------------------------
-- RULE SET #1: ROW COUNTS
-- -----------------------------------------------------------------------------------------------

-- T001 ------------------------------------------------------------------------------------------
	SELECT 'T001' AS tst_id
	     , CASE WHEN COUNT(*) <> 25 THEN 'FAIL' ELSE 'P' END AS status 
	     , '"RS-1 Row Counts" #1 - Verify FullRowCount() = 25 at table [countries]' AS tst_descr   
	FROM demo_hr.countries;


-- T002 ------------------------------------------------------------------------------------------
	SELECT 'T002' AS tst_id
         , CASE WHEN COUNT(*) <> 8 THEN 'FAIL' ELSE 'P' END AS status   
         , '"RS-1 Row Counts" #2 - Verify PartialRowCount() = 8 where [region_id] = 1 (Europe) in table [countries]' AS tst_descr   
	FROM demo_hr.countries
	WHERE region_id = 1;


-- T003 ------------------------------------------------------------------------------------------
	SELECT 'T003' AS tst_id
         , CASE WHEN countries_count < 5 * regions_count THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-1 Row Counts" #3 - Verify RelativeRowCount() table [countries] row count >= 5x table [regions] row count' AS tst_descr   
    FROM (
    	SELECT (SELECT COUNT(*) AS row_count FROM demo_hr.countries) AS countries_count 
    	     , (SELECT COUNT(*) AS row_count FROM demo_hr.regions)   AS regions_count
    ) t;


-- T004 ------------------------------------------------------------------------------------------
	SELECT 'T004' AS tst_id
         , CASE WHEN row_count < 5 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-1 Row Counts" #4 - Verify RecentRowCount() >= 5 in table [countries] where [date_last_updated] in past' AS tst_descr   
	FROM (
        SELECT COUNT(*) AS row_count 
        FROM demo_hr.countries
        WHERE date_last_updated >= DATE_SUB(NOW(), INTERVAL 150 DAY)
	) t;



-- -----------------------------------------------------------------------------------------------
-- RULE SET #2: KEYS
-- -----------------------------------------------------------------------------------------------

-- T005 ------------------------------------------------------------------------------------------
    SELECT 'T005' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-2 Keys" #1 - Verify UkeyHasNoDups() for UKey [country_name] in table [countries]' AS tst_descr   
    FROM (
        SELECT country_name             -- UKey fields 
    	     , COUNT(*) AS match_count 
    	FROM demo_hr.countries          -- UKey fields 
    	GROUP BY country_name 
    	HAVING COUNT(*) > 1
    ) t;


-- T006 ------------------------------------------------------------------------------------------
    SELECT 'T006' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-2 Keys" #2 - Verify FKeyChildNotOrphans() at FKey-Child [region_id] in table [countries]' AS tst_descr   
    FROM (
    	SELECT DISTINCT c.region_id AS child_id, p.region_id AS parent_id
    	FROM      demo_hr.countries c 
    	LEFT JOIN demo_hr.regions   p  ON p.region_id = c.region_id
    	WHERE p.region_id IS NULL
    ) t;


-- T007 ------------------------------------------------------------------------------------------
    SELECT 'T007' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-2 Keys" #3 - Verify FKeyParentHasChildren() at FKey-Parent [country_id] in table [countries] for select Countries' AS tst_descr   
    FROM (
        SELECT DISTINCT c.country_id AS child_id, p.country_id AS parent_id
    	FROM      demo_hr.countries p 
    	LEFT JOIN demo_hr.locations c  ON p.country_id = c.country_id
    	WHERE c.country_id IS NULL
    	  AND p.country_id IN('IT','JP','US','CA','CN','IN','AU','SG','UK','DE','CH','NL','MX')
	) t; 


	
-- -----------------------------------------------------------------------------------------------
-- RULE SET #3: HEURISTICS - RATES AT WHICH NULLS OR OTHER VALUES OCCUR RELATIVE TO THRESHOLDS
-- -----------------------------------------------------------------------------------------------

-- T008 ------------------------------------------------------------------------------------------
    WITH dtls AS (
        SELECT CASE WHEN nr_dept_nm > 0.0000 THEN CONCAT('REJ-01: Null rate too high at department_name|exp=0.0000|act=', CAST(nr_dept_nm AS CHAR(8)) )
                    WHEN nr_mgr_id  > 0.6500 THEN CONCAT('REJ-02: Null rate too high at manager_id|exp<=0.6500|act=', CAST(nr_mgr_id AS CHAR(8)) )
                    WHEN nr_url     > 0.8000 THEN CONCAT('REJ-03: Null rate too high at url|exp<=0.8000|act=', CAST(nr_url AS CHAR(8)) )
                    ELSE 'P'
               END AS status
        FROM (
            SELECT CAST(SUM(CASE WHEN department_name IS NULL THEN 1 ELSE 0 END) AS DECIMAL(10, 5)) / CAST(COUNT(*) AS DECIMAL(10, 5)) AS nr_dept_nm
                 , CAST(SUM(CASE WHEN manager_id      IS NULL THEN 1 ELSE 0 END) AS DECIMAL(10, 5)) / CAST(COUNT(*) AS DECIMAL(10, 5)) AS nr_mgr_id
                 , CAST(SUM(CASE WHEN url             IS NULL THEN 1 ELSE 0 END) AS DECIMAL(10, 5)) / CAST(COUNT(*) AS DECIMAL(10, 5)) AS nr_url
            FROM demo_hr.departments
        ) t
    ) 
    
    SELECT 'T008' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status 
         , '"RS-3 Heuristics" #1 - Verify NullRateThresholds() for specific columns (eg: columnX is NULL for < 5% of the data ) in table [countries]' AS tst_descr   
    FROM dtls 
    WHERE status <> 'P';


-- T009 ------------------------------------------------------------------------------------------
    WITH dtls AS (
        SELECT region_id, freq_rt
             , CASE WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.28 AND 0.36 THEN CONCAT('REJ-01: Frequency occurrence of region_id=1 is outside threshold|exp=0.28 thru 0.36|act=' , CAST(freq_rt AS CHAR(8)))
                    WHEN region_id = 2  AND freq_rt NOT BETWEEN 0.16 AND 0.24 THEN CONCAT('REJ-02: Frequency occurrence of region_id=2 is outside threshold|exp=0.16 thru 0.24|act=' , CAST(freq_rt AS CHAR(8)))
                    WHEN region_id = 3  AND freq_rt NOT BETWEEN 0.20 AND 0.28 THEN CONCAT('REJ-03: Frequency occurrence of region_id=3 is outside threshold|exp=0.20 thru 0.28|act=' , CAST(freq_rt AS CHAR(8)))
                    WHEN region_id = 4  AND freq_rt NOT BETWEEN 0.20 AND 0.28 THEN CONCAT('REJ-04: Frequency occurrence of region_id=4 is outside threshold|exp=0.20 thru 0.28|act=' , CAST(freq_rt AS CHAR(8)))
                    ELSE 'P'
               END AS status
        FROM (
            SELECT region_id, CAST(freq AS FLOAT) / CAST(den AS FLOAT) AS freq_rt
        	FROM (
        	    SELECT region_id, COUNT(*) AS freq
        	    , (SELECT COUNT(*) FROM demo_hr.countries) AS den
                FROM demo_hr.countries
                GROUP BY region_id
            ) t
        ) t2
    )
    
    SELECT 'T009' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status 
         , '"RS-3 Heuristics" #2 - Verify ValueFrequencyThresholds()" for [region_id] values (eg: value=1 for 28% to 36% of rows) in table [countries]' AS tst_descr   
    FROM dtls 
    WHERE status <> 'P';
    


-- -----------------------------------------------------------------------------------------------
-- RULE SET #4: NUMERIC VALUES
-- -----------------------------------------------------------------------------------------------

-- T010 ------------------------------------------------------------------------------------------
	SELECT 'T010' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-4 Numeric" #1 - Verify NoNulls() at [region_id] in table [countries]' AS tst_descr   
	FROM demo_hr.countries
	WHERE region_id IS NULL;

	
-- T011 ------------------------------------------------------------------------------------------
	SELECT 'T011' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-4 Numeric" #2 - Verify NotNegative() where [region_id] >= 0 in table [countries]' AS tst_descr   
	FROM demo_hr.countries
	WHERE region_id < 0;

	
-- T012 ------------------------------------------------------------------------------------------
    SELECT 'T012' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-4 Numeric" #3 - Verify NumericRange() where [employee_id] between 100 and 999 in table [employees]' AS tst_descr   
    FROM (
    	SELECT employee_id
             , CASE WHEN employee_id < 100   THEN CONCAT('REJ-01: Verify employee_id > 99|exp>99|act=', CAST(employee_id AS CHAR(10)) )
	                WHEN employee_id > 999   THEN CONCAT('REJ-02: Verify employee_id < 1000|exp<1000|act=', CAST(employee_id AS CHAR(10)) )
	                ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T013 ------------------------------------------------------------------------------------------
    SELECT 'T013' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-4 Numeric" #4 - Verify InValueList() where [region_id] is in list (1,2,3,4) at table [countries]' AS tst_descr   
    FROM (
    	SELECT region_id
             , CASE WHEN region_id NOT IN(1,2,3,4) THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    ) t
    WHERE status <> 'P';


-- T014 ------------------------------------------------------------------------------------------
    SELECT 'T014' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-4 Numeric" #5 - Verify NotInValueList() where [region_id] is not in list (97,98,99) at table [countries]' AS tst_descr   
    FROM (
    	SELECT region_id
             , CASE WHEN region_id IN(97,98,99) THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    ) t
    WHERE status <> 'P';


-- T015 ------------------------------------------------------------------------------------------
    SELECT 'T015' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-4 Numeric" #6 - Verify MultiFieldCompare() where [salary] x [commission_pct] <= $10,000 cap in table [employees]' AS tst_descr   
    FROM (
        SELECT salary, commission_pct
             , CASE WHEN salary * commission_pct > 10000 THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';



-- -----------------------------------------------------------------------------------------------
-- RULE SET #5: DATE VALUES
-- -----------------------------------------------------------------------------------------------

-- T016 ------------------------------------------------------------------------------------------
    SELECT 'T016' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-5 Dates" #1 - Verify NoNulls() where [date_last_updated] has no nulls in table [countries]' AS tst_descr   
    FROM (
    	SELECT date_last_updated
             , CASE WHEN date_last_updated IS NULL THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    ) t
    WHERE status <> 'P';

	
-- T017 ------------------------------------------------------------------------------------------
    SELECT 'T017' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-5 Dates" #2 - Verify DateRange() where [date_last_updated] is not in the future nor too "old" at table [countries]' AS tst_descr   
    FROM (
    	SELECT date_last_updated
             , CASE WHEN date_last_updated > NOW()        THEN CONCAT('REJ-01: Field date_last_updated cannot be in the future|exp<=', CAST(NOW() AS CHAR(20)), '|act=', CAST(date_last_updated AS CHAR(20)) )
	                WHEN date_last_updated < '2021-01-01' THEN CONCAT('REJ-02: Field date_last_updated cannot be too old|exp>=1/1/2021|act=', CAST(date_last_updated AS CHAR(20)) )
	                ELSE 'P'
    	       END AS status
    	FROM demo_hr.countries
    ) t
    WHERE status <> 'P';


-- T018 ------------------------------------------------------------------------------------------
    SELECT 'T018' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-5 Dates" #3 - Verify NoTimePart() where [hire_date] has no time part (is "12:00:00") in table [employees]' AS tst_descr   
    FROM (
        SELECT hire_date
             , CASE WHEN DATE_FORMAT(hire_date, '%H:%i:%s') <> '00:00:00'THEN 'FAIL' ELSE 'P' END AS status
        FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T019 ------------------------------------------------------------------------------------------
    SELECT 'T019' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-5 Dates" #4 - Verify HasTimePart() where [date_last_updated] has time part (is not 12:00:00) at table [countries]' AS tst_descr   
    FROM (
    	SELECT date_last_updated
             , CASE WHEN DATE_FORMAT(date_last_updated, '%H:%i:%s') = '00:00:00' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    ) t
    WHERE status <> 'P';


-- T020 ------------------------------------------------------------------------------------------
    SELECT 'T020' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-5 Dates" #5 - Verify MultiFieldCompare() where [start_date] must be < [end_date] in table [job_history]' AS tst_descr   
    FROM (
        SELECT start_date, end_date
             , CASE WHEN start_date >= end_date THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.job_history
    ) t
    WHERE status <> 'P';



-- -----------------------------------------------------------------------------------------------
-- RULE SET #6: TEXT VALUES
-- -----------------------------------------------------------------------------------------------

-- T021 ------------------------------------------------------------------------------------------
    SELECT 'T021' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #01 - Verify NoNulls() where [country_name] has no nulls in table [countries]' AS tst_descr   
    FROM (
    	SELECT country_name
             , CASE WHEN country_name IS NULL THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    ) t
    WHERE status <> 'P';


-- T022 ------------------------------------------------------------------------------------------
    SELECT 'T022' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #02 - Verify NoNullStrings() where space (Oracle does not support "" nullstring) in [country_name] at table [countries]' AS tst_descr   
    FROM (
    	SELECT country_name
             , CASE WHEN country_name = '' THEN 'FAIL' ELSE 'P'  END AS status
    	FROM demo_hr.countries
    ) t
    WHERE status <> 'P';

	
-- T023 ------------------------------------------------------------------------------------------
    SELECT 'T023' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #03 - Verify NoLeadTrailSpaces() at [country_name] in table [countries]' AS tst_descr   
    FROM (
    	SELECT country_name
             , CASE WHEN country_name LIKE ' %'  THEN CONCAT('REJ-02: Verify no leading space at country_name|exp=noLeadSpace|act=''', country_name, '''')
				    WHEN country_name LIKE '% '  THEN CONCAT('REJ-03: Verify no trailing space at country_name|exp=noTrailingSpace|act=''', country_name, '''')
	                ELSE 'P'
    	       END AS status
    	FROM demo_hr.countries
    ) t
    WHERE status <> 'P';


-- T024 ------------------------------------------------------------------------------------------
    SELECT 'T024' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #04 - Verify InValueList() where [job_id] is in list of valid values for table [employees]' AS tst_descr   
    FROM (
    	SELECT job_id
             , CASE WHEN job_id NOT IN('ST_MAN','ST_CLERK','SH_CLERK','SA_REP','SA_MAN','PU_CLERK','PR_REP','MK_REP','MK_MAN','IT_PROG'
                                      ,'HR_REP','FI_MGR','FI_ACCOUNT','AD_VP','AD_PRES','AD_ASST','AC_MGR','AC_ACCOUNT','PU_MAN')
                    THEN 'FAIL'
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T025 ------------------------------------------------------------------------------------------
    SELECT 'T025' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #05 - Verify NotInValueList() where [job_id] not in list of invalid values at table [employees]' AS tst_descr   
    FROM (
    	SELECT job_id
             , CASE WHEN job_id IN('CEO','CFO','COO','CIO','POTUS') THEN 'FAIL'  ELSE 'P'  END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T026 ------------------------------------------------------------------------------------------
    SELECT 'T026' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #06 - Verify MultiFieldCompare() where [email] = first letter of [first_name] + [last_name] in table [employees]' AS tst_descr   
    FROM (
    	SELECT email, first_name, last_name
             , CASE WHEN email <> SUBSTRING(UPPER(SUBSTRING(first_name, 1, 1) + last_name), 1, 8) THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    	WHERE email NOT IN('DRAPHEAL', 'JAMRLOW', 'JMURMAN', 'LDEHAAN', 'JRUSSEL', 'TJOLSON')  
    	                 -- DRAPHAEL vs DRAPHEAL, JMARLOW vs JAMRLOW, JMURMAN vs JURMAN, LDE HAAN VS LDEHAAN, JRUSSELL vs JRUSSEL, TOLSON vs TJOLSON 
    ) t
    WHERE status <> 'P';


-- T027 ------------------------------------------------------------------------------------------
    SELECT 'T027' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #07 - Verify TextLEN() where [phone_number] length is 12 or 18 characters in table [employees]' AS tst_descr   
    FROM (
    	SELECT phone_number
             , CASE WHEN LENGTH(phone_number) NOT IN(12,18)  THEN CONCAT('REJ-01: Verify phone_number length is allowed|exp=12,18|act=', CAST(LENGTH(phone_number) AS CHAR(6)))
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';
	

-- T028 ------------------------------------------------------------------------------------------
    SELECT 'T028' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #08 - Verify UpperLowerCaseChars() where [lastname] has all LCase after first character and [job_id] is all UCase in table [employees]' AS tst_descr   
    FROM (
    	SELECT job_id, last_name
             , CASE WHEN job_id COLLATE utf8mb4_bin <> UPPER(job_id)             THEN CONCAT('REJ-01: Verify job_id does not contain lower case characters|exp=ucase|act=', job_id)
	                WHEN SUBSTRING(last_name COLLATE utf8mb4_bin, 2, 255) 
				      <> LOWER(SUBSTRING(last_name COLLATE utf8mb4_bin, 2, 255)) THEN CONCAT('REJ-02: Verify last_name after first char is all lower case|exp=lcase|act=', last_name)
	                ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';
	

-- T029 ------------------------------------------------------------------------------------------
    SELECT 'T029' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #09 - Verify AlphaNumericChars() where [employee_id] is numeric, and [lastname] is alpha in table [employees]' AS tst_descr   
    FROM (
    	SELECT employee_id, last_name
             , CASE WHEN employee_id REGEXP '[A-Za-z]' THEN CONCAT('REJ-01: Verify employee_id does not contain alpha characters|exp=no-alphas|act=', CAST(employee_id AS CHAR(20)))
                    WHEN last_name REGEXP '[0-9]'      THEN CONCAT('REJ-02: Verify last_name does not contain numeric digits|exp=no-digits|act=', last_name)
	                ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T030 ------------------------------------------------------------------------------------------
    SELECT 'T030' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #10 - Verify No_Quote_Chars() where [first_name] has no quotes or apostrophes in table [employees]' AS tst_descr   
    FROM (
    	SELECT first_name
             , CASE WHEN first_name LIKE '%''%'  THEN CONCAT('REJ-01: Verify first_name does not contain single quote characters|exp=none|act=', first_name)
                    WHEN first_name LIKE '%"%'   THEN CONCAT('REJ-02: Verify first_name does not contain quotation characters|exp=none|act=', first_name)
                ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T031 ------------------------------------------------------------------------------------------
    SELECT 'T031' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #11 - Verify No_CRLF_Chars() where [last_name] has no Carriage Returns (CHAR-13) or Line Feeds (CHAR-10) in table [employees]' AS tst_descr   
    FROM (
        SELECT last_name
             , CASE WHEN LOCATE(last_name, CHAR(10))  > 0 THEN CONCAT('REJ-01: Field last_name has a Line Feed (CHAR-10)|exp=none|act=at position ' 
	                                                          , CAST(LOCATE(last_name, CHAR(10 using ASCII)) AS CHAR(4)))
	                WHEN LOCATE(last_name, CHAR(13))  > 0 THEN CONCAT('REJ-02: Field last_name has a Carriage Return (CHAR-13)|exp=none|act=at position ' 
				                                              , CAST(LOCATE(last_name, CHAR(13 using ASCII)) AS CHAR(4)))
	                ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T032 ------------------------------------------------------------------------------------------
    SELECT 'T032' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #12 - Verify No_TAB_Chars() where [last_name] has no TAB characters (CHAR-9) in table [employees]' AS tst_descr   
    FROM (
    	SELECT last_name
             , CASE WHEN LOCATE(last_name, CHAR(9 using ASCII)) > 0 THEN CONCAT('REJ-01: Field last_name has a Tab (CHAR-9)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(9 using ASCII)) AS CHAR(4))) 
                    ELSE 'P'
			   END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T033 ------------------------------------------------------------------------------------------
    SELECT 'T033' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #13 - Verify No_NBS_Chars() where [last_name] has no Non-Breaking-Spaces (CHAR-160) in table [employees]' AS tst_descr   
    FROM (
    	SELECT last_name
             , CASE WHEN LOCATE(last_name, CHAR(160 using ASCII)) > 0 THEN CONCAT('REJ-01: Field last_name has a Non-Breaking-Space (CHAR-160)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(160 using ASCII)) AS CHAR(4)))
                    ELSE 'P' 
			   END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T034 ------------------------------------------------------------------------------------------
    SELECT 'T034' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #14 - Verify No_EmDash_Chars() where [last_name] has an EmDash character (CHAR-151...common Microsoft Word "--" conversion causing data load issues) in table [employees]' AS tst_descr   
    FROM (
    	SELECT last_name
             , CASE WHEN LOCATE(last_name, CHAR(151 using ASCII)) > 0 THEN CONCAT('REJ-01: Field last_name has a Non-Breaking-Space (CHAR-151)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(151 using ASCII)) AS CHAR(4)))
                    ELSE 'P' 
			   END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T035 ------------------------------------------------------------------------------------------
    SELECT 'T035' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #15 - Verify No_VTFFNEL_Chars() where [last_name] has Vertical Tabs (CHAR-11), Form Feeds (CHAR-12) or Next Lines (CHAR-133) in table [employees]' AS tst_descr   
    FROM (
    	SELECT last_name
             , CASE WHEN LOCATE(last_name, CHAR(11 using ASCII)) > 0  THEN CONCAT('REJ-01: Field last_name has a Vertical Tab (CHAR-11)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(11 using ASCII)) AS CHAR(4)))
	                WHEN LOCATE(last_name, CHAR(12 using ASCII)) > 0  THEN CONCAT('REJ-02: Field last_name has a Form Feed (CHAR-12)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(12 using ASCII)) AS CHAR(4)))
	                WHEN LOCATE(last_name, CHAR(133 using ASCII)) > 0 THEN CONCAT('REJ-03: Field last_name has a Next Line (CHAR-133)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(133 using ASCII)) AS CHAR(4)))
	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T036 ------------------------------------------------------------------------------------------
    SELECT 'T036' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #16 - Verify No_PeriodDash_Chars() where [last_name] has periods or dashes in table [employees]' AS tst_descr   
    FROM (
    	SELECT last_name
             , CASE WHEN LOCATE(last_name, '.') > 0 THEN CONCAT('REJ-01: Field last_name has a period|exp=none|act=at position ', CAST(LOCATE(last_name, '.') AS CHAR(4)))
	                WHEN LOCATE(last_name, '0') > 0 THEN CONCAT('REJ-02: Field last_name has a dash|exp=none|act=at position ', CAST(LOCATE(last_name, '-') AS CHAR(4)))
	                ELSE 'P' 
			   END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T037 ------------------------------------------------------------------------------------------
    SELECT 'T037' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #17 - Verify NoBadChars() where [last_name] has no funky punctuation ",/:()&#?;" in table [employees]' AS tst_descr   
    FROM (
    	SELECT last_name
             , CASE WHEN last_name REGEXP '[,/:()&#?;]' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T038 ------------------------------------------------------------------------------------------
    SELECT 'T038' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #18 - Verify OnlyAllowedChars() where [phone_number] only has characters ".0123456789" in table [employees]' AS tst_descr   
    FROM (
    	SELECT phone_number
             , CASE WHEN phone_number REGEXP '[^.0123456789]' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';



-- T039 ------------------------------------------------------------------------------------------
    SELECT 'T039' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #19 - Verify LikeWildcards() where [phone_number] contains a ''.'' and matches valid patterns in table [employees]' AS tst_descr   
    FROM (
    	SELECT phone_number
             , CASE WHEN phone_number NOT LIKE '%.%'                THEN CONCAT('REJ-01: Verify phone_number contains a ''.''|exp=contains-.|act=', phone_number)
                    WHEN phone_number NOT LIKE '___.___.____' 
                     AND phone_number NOT LIKE '011.__.____._____%' THEN CONCAT('REJ-02: Verify phone_number like pattern "___.___.____" or "011.__.____._____"|exp=yes|act=', phone_number)
	                ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T040 ------------------------------------------------------------------------------------------
    SELECT 'T040' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #20 - Verify IsNumeric() where [zip5] will convert to numeric in table [employees]' AS tst_descr   
    FROM (
    	SELECT zip5
             , CASE WHEN zip5 REGEXP '[^0-9]' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T041 ------------------------------------------------------------------------------------------
    SELECT 'T041' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #21 - Verify IsDate("yyyymmdd") where [some_date_fmt1] has date fmt="yyyymmd" in table [employees]' AS tst_descr   
    FROM (
    	SELECT some_date_fmt1
             , CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                         some_date_fmt1,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9','')
                         > ''                                                        THEN CONCAT('REJ-01: Unexpected chars exist (numeric 0-9 only)|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
                    WHEN NOT LENGTH(TRIM(some_date_fmt1)) = 8                        THEN CONCAT('REJ-02: Must be 8 Chars|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
                    WHEN NOT SUBSTRING(some_date_fmt1,1,4) BETWEEN '1753' AND '9999' THEN CONCAT('REJ-03: Year Not Btw 1753-9999|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
                    WHEN NOT SUBSTRING(some_date_fmt1,5,2) BETWEEN '01' AND '12'     THEN CONCAT('REJ-04: Month Not Btw 01-12|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
                    WHEN NOT SUBSTRING(some_date_fmt1,7,2) BETWEEN '01' AND '31'     THEN CONCAT('REJ-05: Day Not Btw 01-31|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
                    ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T042 ------------------------------------------------------------------------------------------
    SELECT 'T042' AS tst_id
         , '"RS-6 Text" #22 - Verify IsDate("mm/dd/yyyy") where [some_date_fmt2] has date fmt="mm/dd/yyyy" in table [employees]' AS tst_descr   
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT some_date_fmt2
             , CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                         some_date_fmt2,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'/','')
                         > ''                                                        THEN CONCAT('REJ-01: Unexpected Chars Exist|exp=Fmt="mm/dd/yyyy"|act=', some_date_fmt2)
                    WHEN NOT LENGTH(TRIM(some_date_fmt2)) = 10                       THEN CONCAT('REJ-02: Must be 10 Chars|exp=Fmt="mm/dd/yyyy"|act=', some_date_fmt2)
                    WHEN NOT SUBSTRING(some_date_fmt2,7,4) BETWEEN '1753' AND '9999' THEN CONCAT('REJ-03: Year Not Btw 1753-9999|exp=Fmt="mm/dd/yyyy"|act=', some_date_fmt2)
                    WHEN NOT SUBSTRING(some_date_fmt2,1,2) BETWEEN '01' AND '12'     THEN CONCAT('REJ-04: Month Not Btw 01-12|exp=Fmt="mm/dd/yyyy"|act=', some_date_fmt2)
                    WHEN NOT SUBSTRING(some_date_fmt2,4,2) BETWEEN '01' AND '31'     THEN CONCAT('REJ-05: Day Not Btw 01-31|exp=Fmt="mm/dd/yyyy"|act=', some_date_fmt2)
                    ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T043 ------------------------------------------------------------------------------------------
    SELECT 'T043' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #23 - Verify IsDate("mm-dd-yyyy") where [some_date_fmt3] has date fmt="mm-dd-yyyy" in table [employees]' AS tst_descr   
    FROM (
    	SELECT some_date_fmt3
             , CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                         some_date_fmt3,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'-','')
                         > ''                                                        THEN CONCAT('REJ-01: Unexpected Chars Exist|exp=Fmt="mm-dd-yyyy"|act=', some_date_fmt3)
                    WHEN NOT LENGTH(TRIM(some_date_fmt3)) = 10                       THEN CONCAT('REJ-02: Must be 10 Chars|exp=Fmt="mm-dd-yyyy"|act=', some_date_fmt3)
                    WHEN NOT SUBSTRING(some_date_fmt3,7,4) BETWEEN '1753' AND '9999' THEN CONCAT('REJ-03: Year Not Btw 1753-9999|exp=Fmt="mm-dd-yyyy"|act=', some_date_fmt3)
                    WHEN NOT SUBSTRING(some_date_fmt3,1,2) BETWEEN '01' AND '12'     THEN CONCAT('REJ-04: Month Not Btw 01-12|exp=Fmt="mm-dd-yyyy"|act=', some_date_fmt3)
                    WHEN NOT SUBSTRING(some_date_fmt3,4,2) BETWEEN '01' AND '31'     THEN CONCAT('REJ-05: Day Not Btw 01-31|exp=Fmt="mm-dd-yyyy"|act=', some_date_fmt3)
                    ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T044 ------------------------------------------------------------------------------------------
    SELECT 'T044' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-6 Text" #24 - Verify IsDate("yyyy-mm-dd") where [some_date_fmt4] has date fmt="yyyy-mm-dd" in table [employees]' AS tst_descr   
    FROM (
    	SELECT some_date_fmt4
             , CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                         some_date_fmt4,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'-','')
                         > ''                                                        THEN CONCAT('REJ-01: Unexpected Chars Exist|exp=Fmt="yyyy-mm-dd"|act=', some_date_fmt4)
                    WHEN NOT LENGTH(TRIM(some_date_fmt4)) = 10                       THEN CONCAT('REJ-02: Must be 10 Chars|exp=Fmt="yyyy-mm-dd"|act=', some_date_fmt4)
                    WHEN NOT SUBSTRING(some_date_fmt4,1,4) BETWEEN '1753' AND '9999' THEN CONCAT('REJ-03: Year Not Btw 1753-9999|exp=Fmt="yyyy-mm-dd"|act=', some_date_fmt4)
                    WHEN NOT SUBSTRING(some_date_fmt4,6,2) BETWEEN '01' AND '12'     THEN CONCAT('REJ-04: Month Not Btw 01-12|exp=Fmt="yyyy-mm-dd"|act=', some_date_fmt4)
                    WHEN NOT SUBSTRING(some_date_fmt4,9,2) BETWEEN '01' AND '31'     THEN CONCAT('REJ-05: Day Not Btw 01-31|exp=Fmt="yyyy-mm-dd"|act=', some_date_fmt4)
                    ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';



-- -----------------------------------------------------------------------------------------------
-- RULE SET #7: REGULAR EXPRESSIONS
-- -----------------------------------------------------------------------------------------------

-- T045 ------------------------------------------------------------------------------------------
    SELECT 'T045' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #01 - Verify RegExp("IsPhoneNumber") where phone_number matches RegEx pattern "[0-9]{3}[-. ][0-9]{3}[-. ][0-9]{4}" in table [employees]' AS tst_descr   
    FROM (
        -- NOTE: Use RegEx pattern "^\+(\d+\s?)+$" for international phone numbers
        SELECT phone_number
             , CASE WHEN NOT phone_number REGEXP '^[0-9][0-9][0-9][-. ][0-9][0-9][0-9][-. ][0-9][0-9][0-9][0-9]$' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T046 ------------------------------------------------------------------------------------------
    SELECT 'T046' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #02 - Verify RegExp("IsSSN") where [fake_ssn] matches RegEx pattern "^[0-9]{3}-[0-9]{2}-[0-9]{4}$" in table [employees]' AS tst_descr   
    FROM (
    	SELECT fake_ssn
             , CASE WHEN NOT fake_ssn REGEXP '^[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]$' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T047 ------------------------------------------------------------------------------------------
    SELECT 'T047' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #03 - Verify RegExp("IsZip5") where [zip5] matches RegEx pattern "^[0-9]{5}$" in table [employees]' AS tst_descr   
    FROM (
    	SELECT zip5
             , CASE WHEN NOT zip5 REGEXP('^[0-9][0-9][0-9][0-9][0-9]$') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T048 ------------------------------------------------------------------------------------------
    SELECT 'T048' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #04 - Verify RegExp("IsZip5or9") where [zip5or9] matches RegEx pattern "^[[:digit:]]{5}(-[[:digit:]]{4})?$" in table [employees]' AS tst_descr   
    FROM (
    	SELECT zip5or9
             , CASE WHEN NOT zip5or9 REGEXP '^[0-9][0-9][0-9][0-9][0-9]$'
	                 AND NOT zip5or9 REGEXP '^[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]$' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T049 ------------------------------------------------------------------------------------------
    SELECT 'T049' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #05 - Verify RegExp("IsZip9") where [zip9] matches RegEx pattern WHEN NOT zip9 REGEXP ''^[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]$'' in table [employees]' AS tst_descr   
    FROM (
    	SELECT zip9
             , CASE WHEN NOT zip9 REGEXP '^[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]$' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T050 ------------------------------------------------------------------------------------------
    SELECT 'T050' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #06 - Verify RegExp("OnlyText") where [last_name] matches RegEx pattern "^[a-zA-Z ]+$" in table [employees]' AS tst_descr   
    FROM (
    	SELECT last_name
             , CASE WHEN last_name REGEXP '[^a-zA-Z ]' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T051 ------------------------------------------------------------------------------------------
    SELECT 'T051' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #07 - Verify RegExp("OnlyNumeric") where [zip5] matches RegEx pattern "^[0-9]+$" in table [employees]' AS tst_descr   
    FROM (
    	SELECT zip5
             , CASE WHEN zip5 REGEXP '[^0-9.]' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T052 ------------------------------------------------------------------------------------------
    SELECT 'T052' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #08 - Verify RegExp("NoLeadTrailSpaces") where [last_name] matches RegEx pattern "(^\s)|(\s$)" in table [employees]' AS tst_descr   
    FROM (
    	SELECT last_name
             , CASE WHEN last_name REGEXP '^ ' OR last_name REGEXP ' $' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T053 ------------------------------------------------------------------------------------------
    SELECT 'T053' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #09 - Verify RegExp("NoWhitespaces") where [job_id] matches RegEx pattern "(\s)+" in table [employees]' AS tst_descr   
    FROM (
    	SELECT job_id
             , CASE WHEN job_id REGEXP '[[:space:]]' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T054 ------------------------------------------------------------------------------------------
    SELECT 'T054' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #10 - Verify RegExp("OnlyLowerCase") at 3rd and 4th chars of [first_name] matching RegEx pattern "^[a-z]+$" in table [employees]' AS tst_descr   
    FROM (
    	SELECT first_name
             , CASE WHEN SUBSTRING(first_name COLLATE utf8mb4_bin, 3, 2) <> LOWER(SUBSTRING(first_name COLLATE utf8mb4_bin, 3, 2))   
	                THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T055 ------------------------------------------------------------------------------------------
    SELECT 'T055' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #11 - Verify RegExp("OnlyUpperCase") where [email] matching RegEx pattern "^[A-Z]+$" in table [employees]' AS tst_descr   
    FROM (
    	SELECT email
             , CASE WHEN SUBSTRING(email COLLATE utf8mb4_bin, 3, 2) <> UPPER(SUBSTRING(email COLLATE utf8mb4_bin, 3, 2)) 
	                 THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T056 ------------------------------------------------------------------------------------------
    SELECT 'T056' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #12 - Verify RegExp("TitleCase") where [first_name] upper cases first letter second name too and matches RegEx pattern "(\s[A-Z]){1}" in table [employees]' AS tst_descr   
    FROM (
    	SELECT first_name, SUBSTRING(first_name,1,1) AS first_letter
             , CASE WHEN NOT first_name COLLATE utf8mb4_bin REGEXP '^[A-Z].*'        THEN CONCAT('REJ-01: Field first_name first character not uppercase|exp=Like"^[A-Z]"|act=', first_name) 
                    WHEN NOT first_name COLLATE utf8mb4_bin REGEXP '^[A-Z][a-z]+.*'  THEN CONCAT('REJ-02: Field first_name characters in first word after first character not lowercase|exp=all lower case"|act=', first_name)
                    WHEN first_name NOT LIKE '% %'                                   THEN 'allgood'  -- Only one word, so no space + first character to check for uppercase
                    WHEN NOT first_name COLLATE utf8mb4_bin REGEXP ' [A-Z]'          THEN CONCAT('REJ-03: Field first_name first character after space is not uppercase|exp=IsUCASE|act=', first_name )
                    WHEN NOT first_name COLLATE utf8mb4_bin REGEXP ' [A-Z][a-z]+'    THEN CONCAT('REJ-04: Field first_name characters after space + one letter are not lowercase|exp=IsUCASE|act=', first_name)
                    ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T057 ------------------------------------------------------------------------------------------
    SELECT 'T057' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #13 - Verify RegExp("EmailAddress") where [email_address] matches RegEx pattern "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$" in table [employees]' AS tst_descr   
    FROM (
    	SELECT email_address
             , CASE WHEN email_address IS NULL                                     THEN CONCAT('REJ-01: Field email_address is NULL', '|exp=meets biz rules|act=', email_address)
                    WHEN email_address = ''                                        THEN CONCAT('REJ-02: Field email_address is blank', '|exp=meets biz rules|act=', email_address)
                    WHEN email_address REGEXP '["(),:;<>\]'                        THEN CONCAT('REJ-03: Field email_address contains bad characters ["(),:;<>\]', '|exp=meets biz rules|act=', email_address)
                    WHEN SUBSTRING(email_address, LOCATE('@', email_address), LENGTH(email_address)) REGEXP '[!#$%&*+/=?^`_{|]'
				                                                                   THEN CONCAT('REJ-04: Field email_address company name after @ contains bad characters [!#$%&*+/=?^`_{|]', '|exp=meets biz rules|act=', email_address)
                    WHEN LEFT(email_address,1) REGEXP '[-_.+]'                     THEN CONCAT('REJ-05: Field email_address should not start with [-_.+] characters', '|exp=meets biz rules|act=', email_address)
                    WHEN RIGHT(email_address,1) REGEXP '[-_.+]'                    THEN CONCAT('REJ-06: Field email_address should not end with [-_.+] characters', '|exp=meets biz rules|act=', email_address)
                    WHEN email_address LIKE '%[%' OR email_address LIKE '%]%'      THEN CONCAT('REJ-07: Field email_address should not contain [ or ] characters', '|exp=meets biz rules|act=', email_address)
                    WHEN email_address LIKE '%@%@%'                                THEN CONCAT('REJ-08: Field email_address should not contain more than one @ character', '|exp=meets biz rules|act=', email_address)
                    WHEN email_address LIKE '\_%@\_%.\_%'                          THEN CONCAT('REJ-09: Field email_address should not have leading underscores at any segment (gmail blocks)', '|exp=meets biz rules|act=', email_address)
                    ELSE 'P' 
	           END AS status
    	FROM demo_hr.employees
    ) t
    WHERE status <> 'P';


-- T058 ------------------------------------------------------------------------------------------
    SELECT 'T058' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"RS-7 RegEx" #14 - Verify RegExp("IsUrl") where [url] matches RegEx pattern "(http)(s)?(:\/\/)" in table [departments]' AS tst_descr   
    FROM (
    	SELECT url
             , CASE WHEN url NOT LIKE'http://%' 
	                 AND url NOT LIKE'https://%'                                 THEN CONCAT('REJ-01: Field url is missing "http://" and "https://"|exp=Like"http(s)://"|act=', url)
	                WHEN url REGEXP '^http[s]*://[A-Z0-9]*[.][A-Z0-9]*[A-Z0-9]$' THEN CONCAT('REJ-02: Field is not alphanumeric + "." + alphanumeric + "/" + alphanumeric|exp=aaaa.aaa|act=', url)
				    ELSE'P' 
			   END AS status
    	FROM demo_hr.departments
    ) t
    WHERE status <> 'P';



-- -----------------------------------------------------------------------------------------------
-- RULE SET #8: DIFF CHECKS
-- -----------------------------------------------------------------------------------------------

-- T059 ------------------------------------------------------------------------------------------
    WITH expected 
    AS (
            SELECT 1 AS ord_pos, 'LOCATION_ID'    AS column_nm, 'decimal(4,0)' AS data_typ, 'NOT NULL' AS nullable
      UNION SELECT 2 AS ord_pos, 'STREET_ADDRESS' AS column_nm, 'varchar(40)'  AS data_typ, 'NULL'     AS nullable
      UNION SELECT 3 AS ord_pos, 'POSTAL_CODE'    AS column_nm, 'varchar(12)'  AS data_typ, 'NULL'     AS nullable
      UNION SELECT 4 AS ord_pos, 'CITY'           AS column_nm, 'varchar(30)'  AS data_typ, 'NOT NULL' AS nullable
      UNION SELECT 5 AS ord_pos, 'STATE_PROVINCE' AS column_nm, 'varchar(25)'  AS data_typ, 'NULL'     AS nullable
      UNION SELECT 6 AS ord_pos, 'COUNTRY_ID'     AS column_nm, 'char(2)'      AS data_typ, 'NULL'     AS nullable
    )
    , actual
    AS (
      SELECT
        RIGHT(CONCAT('000', CAST(tut.ORDINAL_POSITION AS CHAR(3))), 3) AS ord_pos
      , tut.column_name                                                AS column_nm
      , CONCAT(COALESCE(tut.data_type, 'unknown'), 
        CASE WHEN tut.data_type IN('varchar','nvarchar')    THEN CONCAT('(', CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)), ')')
             WHEN tut.data_type IN('char','nchar')          THEN CONCAT('(', CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)), ')')
             WHEN tut.data_type ='date'                     THEN CONCAT('(', CAST(tut.DATETIME_PRECISION AS CHAR(10)), ')')
             WHEN tut.data_type ='datetime'                 THEN CONCAT('(', CAST(tut.DATETIME_PRECISION AS CHAR(10)), ')')
             WHEN tut.data_type LIKE '%int%'                THEN CONCAT('(', CAST(tut.NUMERIC_PRECISION AS CHAR(10)), ')')
             WHEN tut.data_type = 'uniqueidentifier'        THEN '(16)'
             WHEN tut.data_type = 'money'                   THEN CONCAT('(', CAST(tut.NUMERIC_PRECISION AS CHAR(10)), ')')
             WHEN tut.data_type = 'decimal'                 THEN CONCAT('(', CAST(tut.NUMERIC_PRECISION AS CHAR(10)), ',', CAST(tut.NUMERIC_SCALE AS CHAR(10)), ')')
             WHEN tut.data_type = 'numeric'                 THEN CONCAT('(', CAST(tut.NUMERIC_PRECISION AS CHAR(10)), ',', CAST(tut.NUMERIC_SCALE AS CHAR(10)), ')')
             WHEN tut.data_type = 'varbinary'               THEN CONCAT('(', CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)), ')')
             WHEN tut.data_type = 'xml'                     THEN CONCAT('(', CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)), ')')
             WHEN tut.data_type IN('char','nchar')          THEN CONCAT('(', CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)), ')')
             WHEN tut.CHARACTER_MAXIMUM_LENGTH IS NOT NULL  THEN CONCAT('(', CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)), ')')
             WHEN tut.DATETIME_PRECISION IS NOT NULL        THEN CONCAT('(', CAST(tut.DATETIME_PRECISION AS CHAR(10)), ')')
             WHEN tut.NUMERIC_PRECISION IS NOT NULL
              AND tut.NUMERIC_SCALE     IS NULL             THEN CONCAT('(', CAST(tut.NUMERIC_PRECISION AS CHAR(10)), ')')
             WHEN tut.NUMERIC_PRECISION IS NOT NULL
              AND tut.NUMERIC_SCALE     IS NOT NULL         THEN CONCAT('(', CAST(tut.NUMERIC_PRECISION AS CHAR(10)), ',', CAST(tut.NUMERIC_SCALE AS CHAR(10)), ')')
             ELSE ''
        END) AS data_typ
      , CASE WHEN tut.IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END AS nullable
      FROM       INFORMATION_SCHEMA.COLUMNS  tut
      WHERE tut.table_schema  = 'DEMO_HR'
        AND tut.table_name = 'LOCATIONS'
      )
    , dut -- Data Under Test 
    AS (
      SELECT CASE WHEN (SELECT COUNT(*) FROM actual) = 0 THEN 'REJ-01: Table [locations] does not exist (may be case sensistive name)|exp=exists|act=notExist' 
	              WHEN a.column_nm IS NULL               THEN CONCAT('REJ-01: Expected column is missing from actual schema (may be case sensitive name)|exp=', e.column_nm, '|act=IsMissing')
	              WHEN a.ord_pos <> e.ord_pos            THEN CONCAT('REJ-02: Ordinal Positions at field ', e.column_nm, ' do not match|exp=', CAST(e.ord_pos AS CHAR(3)), '|act=', CAST(a.ord_pos AS CHAR(3)))
	              WHEN a.data_typ <> e.data_typ          THEN CONCAT('REJ-03: Data Types at field ', e.column_nm, ' do not match|exp=', e.data_typ, '|act=', a.data_typ )
	              WHEN a.nullable <> e.nullable          THEN CONCAT('REJ-04: Nullable settings at field ', e.column_nm, ' do not match|exp=', e.nullable, '|act=', a.nullable)
	              ELSE 'P'
	         END AS rej_dtls
	       , 'N/A - Go browse to table structure from tree grid in UI' AS lookup_sql
      FROM      expected e 
      LEFT JOIN actual   a ON a.column_nm = e.column_nm
    )

    SELECT 'T059' AS tst_id
         , CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END status
         , '"RS-8 Diffs" #1 - Verify TableStructure("BySQL") by comparing snapshot in SQL code vs actual schema/structure for table [locations]' AS tst_descr   
    FROM dut WHERE rej_dtls <> 'P';
    
    

-- T060 ------------------------------------------------------------------------------------------
    WITH metadata 
    AS (
    	      SELECT 1 AS region_id, 'Europe' AS region_name
    	UNION SELECT 2 AS region_id, 'Americas' AS region_name
    	UNION SELECT 3 AS region_id, 'Asia' AS region_name 
    	UNION SELECT 4 AS region_id, 'Middle East and Africa' AS region_name
    )
    , dut -- Data Under Test 
    AS (
    	SELECT CASE WHEN r.region_id IS NULL            THEN CONCAT('REJ-01: Record is missing from metadata|exp=NotMissing|act=', CAST(m.region_id AS CHAR(4)), ' is missing')
	                WHEN r.region_name <> m.region_name THEN CONCAT('REJ-02: Region_Name does not match|exp=', m.region_name, '|act=', r.region_name)
	                ELSE 'P'
    	       END AS status
    	FROM      metadata   m 
    	LEFT JOIN demo_hr.regions r ON r.region_id = m.region_id
    )
    
    SELECT 'T060' AS tst_id
         , CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END status
         , '"RS-8 Diffs" #2 - Verify TableData("BySQL") - Data should not change for table [regions]' AS tst_descr   
    FROM dut WHERE status <> 'P';


-- T061 ------------------------------------------------------------------------------------------
    WITH non_matches
    AS (
        SELECT MAX(tbl_nm) AS tbl_nm, job_id, job_title, min_salary, max_salary, COUNT(*) AS match_count_found
        FROM (
    		SELECT CAST('jobs' AS CHAR(15)) AS tbl_nm,          job_id, job_title, min_salary, max_salary FROM demo_hr.JOBS  
    		UNION ALL 
    		SELECT CAST('jobs_snapshot' AS CHAR(15)) AS tbl_nm, job_id, job_title, min_salary, max_salary FROM demo_hr.JOBS_SNAPSHOT 
        ) comb_sets 
        GROUP BY job_id, job_title, min_salary, max_salary
        HAVING COUNT(*) < 2
    )
    , dut -- Data Under Test 
    AS (
	SELECT CONCAT('REJ-01: Mismatch Found: tbl_nm="', tbl_nm, '", job_id="', job_id, '", job_title="', job_title 
         , '", min_salary=', CAST(min_salary AS CHAR(20)), '", max_salary=', CAST(max_salary AS CHAR(20))) AS status
         , 'Too complex, better to go manually run the SQL for "non_matches" CTE sub-table' AS lookup_sql
	FROM      non_matches  
    )

    SELECT 'T061' AS tst_id
         , CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END status
         , '"RS-8 Diffs" #3 - Verify TableData("By2TableCompare") - Table data should exactly match between tables [jobs] and [jobs_snapshot]' AS tst_descr   
    FROM dut WHERE status <> 'P';




-- -----------------------------------------------------------------------------------------------
-- RULE SET #9: DEFECT REGRESSION
-- -----------------------------------------------------------------------------------------------

-- This is where you would add on SQL validations (where appropriate) that regression test defects
-- that come up over time.  Most will take the form of one of the example test cases above.




-- -----------------------------------------------------------------------------------------------
-- BEST PRACTICES: 
-- -----------------------------------------------------------------------------------------------

-- T062 ------------------------------------------------------------------------------------------
    WITH dut -- data under test
    AS (
    	SELECT region_id
    	, CAST(freq AS DECIMAL(15, 3)) / CAST(den AS DECIMAL(15, 3)) AS freq_rt
    	FROM (
    	    SELECT region_id, COUNT(*) AS freq
    	    , (SELECT COUNT(*) FROM demo_hr.countries) AS den
            FROM demo_hr.countries
            GROUP BY region_id
        ) t
    )
    , bll -- business logic layer: apply heuristics...what constitutes a pass or a fail?
    AS (
    	SELECT region_id, freq_rt
             , CASE WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.10 AND 0.50 THEN CONCAT('FAIL: Frequency occurrence of region_id=1 is FAR outside threshold|exp=0.28 thru 0.36|act=', CAST(freq_rt AS CHAR(8)))
                    WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.25 AND 0.35 THEN CONCAT('WARN: Frequency occurrence of region_id=1 is outside threshold|exp=0.20 thru 0.28|act=', CAST(freq_rt AS CHAR(8)))
                    ELSE 'P'
    	       END AS status
    	FROM dut
    )
    -- SELECT * FROM bll;
	
    SELECT 'T062' AS tst_id
         , CASE WHEN (SELECT COUNT(*) FROM bll) = 0 THEN 'SKIP'
	            WHEN (SELECT COUNT(*) FROM bll WHERE status LIKE 'FAIL:%') > 0 THEN 'FAIL'
	            WHEN (SELECT COUNT(*) FROM bll WHERE status LIKE 'WARN:%') > 0 THEN 'WARN'
	            ELSE 'P'
	       END AS status
         , '"X#1 WarnSkip" - Verify ValueFrequencyThresholds()" for [region_id] values (eg: value=1 for 28% to 36% of rows) in table [countries]' AS tst_descr   
	;

 
-- T063 ------------------------------------------------------------------------------------------
    SELECT 'T02' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"X#2 LimitToRecent" - VerVerify NoNulls() at [region_id] in table [countries] for past 30 days' AS tst_descr   
    FROM (
    	SELECT region_id, date_last_updated
             , CASE WHEN region_id IS NULL  THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    	WHERE date_last_updated BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()
    ) t
    WHERE status <> 'P';


-- T064 ------------------------------------------------------------------------------------------
    SELECT 'T064' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"X#3 IgnoreBadRows" - Verify NoNulls() at [region_id] in table [countries]; ignoring 3 known bad rows' AS tst_descr   
    FROM (
    	SELECT region_id, country_id
             , CASE WHEN region_id IS NULL  THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    	WHERE country_id NOT IN('BR','DK','IL') 
    ) t
    WHERE status <> 'P';

	
-- T065 ------------------------------------------------------------------------------------------
    SELECT 'T065' AS tst_id
         , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
         , '"X#4 TableScan" - Verify dozens of checks in a single table scan pass against table [employees] for best performance' AS tst_descr   
    FROM (
        SELECT employee_id, salary, commission_pct, hire_date, zip5, job_id, email, first_name, last_name, phone_number, some_date_fmt1
             , CASE WHEN employee_id < 100                                            THEN CONCAT('REJ-01: Field employee_id > 99|exp>99|act=', CAST(employee_id AS CHAR(10)))
                    WHEN employee_id > 999                                            THEN CONCAT('REJ-02: Field employee_id < 1000|exp<1000|act=', CAST(employee_id AS CHAR(10)))
                    WHEN salary * commission_pct > 10000                              THEN CONCAT('REJ-03: Fields salary x commission_pct <= $10,000|exp<10,000|act=', CAST(salary * commission_pct AS CHAR(15)))
                    WHEN DATE_FORMAT(hire_date, '%H:%i:%s') <> '00:00:00'             THEN CONCAT('REJ-04: Field hire_date cannot have a time part|exp=12:00:00|act=', DATE_FORMAT(hire_date, '%H:%i:%s'))
                    WHEN zip5 REGEXP '[^0-9]'                                         THEN CONCAT('REJ-05: Field zip9 will not convert to a number|exp=converts to number|act=', zip5)
                    WHEN job_id IN('CEO','CFO','COO','CIO','POTUS')                   THEN CONCAT('REJ-06: Field job_id not in domain list of excluded values|exp<>1of5|act=', job_id)
                    WHEN email <> SUBSTRING(UPPER(CONCAT(SUBSTRING(first_name, 1, 1)
                                                        , last_name)), 1, 8)          THEN CONCAT('REJ-07: Field email <> first char of first_name + last_name|exp=', SUBSTRING(UPPER(CONCAT(SUBSTRING(first_name, 1, 1), last_name)), 1, 8), '|act=', email)
                    WHEN LENGTH(phone_number) NOT IN(12,18)                           THEN CONCAT('REJ-08: Field phone_number length is allowed|exp=12,18|act=', CAST(LENGTH(phone_number) AS CHAR(6)))
                    WHEN job_id COLLATE utf8mb4_bin <> UPPER(job_id)                  THEN CONCAT('REJ-09: Field job_id does not contain lower case characters|exp=ucase|act=', email)
                    WHEN SUBSTRING(last_name COLLATE utf8mb4_bin, 2, 255) 
                         <> LOWER(SUBSTRING(last_name COLLATE utf8mb4_bin, 2, 255))   THEN CONCAT('REJ-10: Verify last_name after first char is all lower case|exp=lcase|act=', last_name)
                    WHEN employee_id REGEXP '[A-Za-z]'                                THEN CONCAT('REJ-11: Field employee_id does not contain alpha characters|exp=no-alphas|act=', CAST(employee_id AS CHAR(20)))
                    WHEN last_name REGEXP '[0-9]'                                     THEN CONCAT('REJ-12: Field last_name does not contain numeric digits|exp=no-digits|act=', last_name) 
                    WHEN first_name LIKE '%''%'                                       THEN CONCAT('REJ-13: Field first_name does not contain single quote characters|exp=none|act=', first_name)
                    WHEN first_name LIKE '%"%'                                        THEN CONCAT('REJ-14: Field first_name does not contain quotation characters|exp=none|act=', first_name)
                    WHEN LOCATE(last_name, CHAR(10))  > 0                             THEN CONCAT('REJ-15: Field last_name has a Line Feed (CHAR-10)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(10)) AS CHAR(4)))
                    WHEN LOCATE(last_name, CHAR(13))  > 0                             THEN CONCAT('REJ-16: Field last_name has a Carriage Return (CHAR-13)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(13)) AS CHAR(4)))
                    WHEN LOCATE(last_name, CHAR(9))   > 0                             THEN CONCAT('REJ-17: Field last_name has a Tab (CHAR-9)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(9)) AS CHAR(4)))
                    WHEN LOCATE(last_name, CHAR(160)) > 0                             THEN CONCAT('REJ-18: Field last_name has a Non-Breaking-Space (CHAR-160)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(160)) AS CHAR(4)))
                    WHEN LOCATE(last_name, CHAR(151)) > 0                             THEN CONCAT('REJ-19: Field last_name has a Non-Breaking-Space (CHAR-151)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(151)) AS CHAR(4)))
                    WHEN LOCATE(last_name, CHAR(11)) > 0                              THEN CONCAT('REJ-20: Field last_name has a Vertical Tab (CHAR-11)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(11)) AS CHAR(4)))
                    WHEN LOCATE(last_name, CHAR(12)) > 0                              THEN CONCAT('REJ-21: Field last_name has a Form Feed (CHAR-12)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(12)) AS CHAR(4)))
                    WHEN LOCATE(last_name, CHAR(133)) > 0                             THEN CONCAT('REJ-22: Field last_name has a Next Line (CHAR-133)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(133)) AS CHAR(4)))
                    WHEN LOCATE(last_name, '.') > 0                                   THEN CONCAT('REJ-23: Field last_name has a period|exp=none|act=at position ', CAST(LOCATE(last_name, '.') AS CHAR(4)))
                    WHEN last_name REGEXP '[,/:()&#?;]'                               THEN CONCAT('REJ-24: Field last_name has a ",/:()&#?;" characters|exp=none|act=', last_name) 
                    WHEN phone_number REGEXP '[^.0123456789]'                         THEN CONCAT('REJ-25: Field phone_number can only have characters ".012345789"|exp=onlyAlloweChars|act=', phone_number)
                    WHEN phone_number NOT LIKE '%.%'                                  THEN CONCAT('REJ-26: Verify phone_number contains a ''.''|exp=contains-.|act=', phone_number)
                    WHEN phone_number NOT LIKE '___.___.____' 
                     AND phone_number NOT LIKE '011.__.____._____%'                   THEN CONCAT('REJ-27: Verify phone_number like pattern "___.___.____" or "011.__.____._____"|exp=yes|act=', phone_number)
                    WHEN zip5 REGEXP '[^0-9]'                                         THEN CONCAT('REJ-28: Field zip9 will not convert to a number|exp=converts to number|act=', zip5)
                    WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                         REPLACE(REPLACE(REPLACE(some_date_fmt1,'0',''),'1','')
                         ,'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8'
                         ,''),'9','')  > ''                                           THEN CONCAT('REJ-29: Unexpected chars exist (numeric 0-9 only)|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
                    WHEN NOT LENGTH(TRIM(some_date_fmt1)) = 8                         THEN CONCAT('REJ-30: Must be 8 Chars|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
                    WHEN NOT SUBSTRING(some_date_fmt1,1,4) BETWEEN '1753' AND '9999'  THEN CONCAT('REJ-31: Year Not Btw 1753-9999|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
                    WHEN NOT SUBSTRING(some_date_fmt1,5,2) BETWEEN '01' AND '12'      THEN CONCAT('REJ-32: Month Not Btw 01-12|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
                    WHEN NOT SUBSTRING(some_date_fmt1,7,2) BETWEEN '01' AND '31'      THEN CONCAT('REJ-33: Day Not Btw 01-31|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
                    ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
        WHERE email NOT IN('DRAPHEAL', 'JAMRLOW', 'JMURMAN', 'LDEHAAN', 'JRUSSEL', 'TJOLSON')  
    	               -- DRAPHAEL vs DRAPHEAL, JMARLOW vs JAMRLOW, JMURMAN vs JURMAN, LDE HAAN VS LDEHAAN, JRUSSELL vs JRUSSEL, TOLSON vs TJOLSON)
    ) t
    WHERE status <> 'P';




