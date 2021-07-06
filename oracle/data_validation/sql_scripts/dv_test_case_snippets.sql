-- ===============================================================================================
-- Filename:          dv_test_case_snippets.sql
-- Description:       Data Validation Snippets - Verification Check Examples
-- Platform:          Oracle
-- Author:            DataResearchLabs
-- GitHub:            https://github.com/DataResearchLabs/sql_scripts
-- YouTube Tutorials: https://www.youtube.com/channel/UCQciXv3xaBykeUFc04GxSXA
-- ------------------------------------------------------------------------------------------------
-- These SQL snippets lays out a comprehensive set of example data validation checks.
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
-- RULE SET #1: ROW COUNTS
-- -----------------------------------------------------------------------------------------------

-- T001 ------------------------------------------------------------------------------------------
-- "RS-1 Row Counts" #1 - Verify FullRowCount() = 25 at table [countries]

	SELECT CASE WHEN COUNT(*) <> 25 THEN 'FAIL' ELSE 'P' END AS status 
	FROM demo_hr.countries;



-- T002 ------------------------------------------------------------------------------------------
-- "RS-1 Row Counts" #2 - Verify PartialRowCount() = 8 where [region_id] = 1 (Europe) in table [countries]
	
	SELECT CASE WHEN COUNT(*) <> 8 THEN 'FAIL' ELSE 'P' END AS status   
	FROM demo_hr.countries
	WHERE region_id = 1;



-- T003 ------------------------------------------------------------------------------------------
-- "RS-1 Row Counts" #3 - Verify RelativeRowCount() table [countries] row count >= 5x table [regions] row count
	
	SELECT CASE WHEN countries_count < 5 * regions_count THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT (SELECT COUNT(*) AS row_count FROM demo_hr.countries) AS countries_count 
    	     , (SELECT COUNT(*) AS row_count FROM demo_hr.regions)   AS regions_count
    	FROM dual
    );



-- T004 ------------------------------------------------------------------------------------------
-- "RS-1 Row Counts" #4 - Verify RecentRowCount() >= 5 in table [countries] where [date_last_updated] in past

	SELECT CASE WHEN row_count < 5 THEN 'FAIL' ELSE 'P' END AS status
	FROM (
        SELECT COUNT(*) AS row_count 
        FROM demo_hr.countries
        WHERE date_last_updated >= SYSDATE - 100
	);



-- -----------------------------------------------------------------------------------------------
-- RULE SET #2: KEYS
-- -----------------------------------------------------------------------------------------------

-- T005 ------------------------------------------------------------------------------------------
-- "RS-2 Keys" #1 - Verify UkeyHasNoDups() for UKey [country_name] in table [countries]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
        SELECT country_name             -- UKey fields 
    	     , COUNT(*) AS match_count 
    	FROM demo_hr.countries           
    	GROUP BY country_name           -- UKey fields
    	HAVING COUNT(*) > 1
    );



-- T006 ------------------------------------------------------------------------------------------
-- "RS-2 Keys" #2 - Verify FKeyChildNotOrphans() at FKey-Child [region_id] in table [countries]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT DISTINCT c.region_id AS child_id, p.region_id AS parent_id
    	FROM      demo_hr.countries c 
    	LEFT JOIN demo_hr.regions   p  ON p.region_id = c.region_id
    	WHERE p.region_id IS NULL
    );



-- T007 ------------------------------------------------------------------------------------------
-- "RS-2 Keys" #3 - Verify FKeyParentHasChildren() at FKey-Parent [country_id] in table [countries] for select Countries

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
        SELECT DISTINCT c.country_id AS child_id, p.country_id AS parent_id
    	FROM      demo_hr.countries p 
    	LEFT JOIN demo_hr.locations c  ON p.country_id = c.country_id
    	WHERE c.country_id IS NULL
    	  AND p.country_id IN('IT','JP','US','CA','CN','IN','AU','SG','UK','DE','CH','NL','MX')
	); 


	
-- -----------------------------------------------------------------------------------------------
-- RULE SET #3: HEURISTICS - RATES AT WHICH NULLS OR OTHER VALUES OCCUR RELATIVE TO THRESHOLDS
-- -----------------------------------------------------------------------------------------------

-- T008 ------------------------------------------------------------------------------------------
-- "RS-3 Heuristics" #1 - Verify NullRateThresholds() for specific columns (eg: columnX is NULL for < 5% of the data ) in table [countries]

    WITH dtls AS (
        SELECT CASE WHEN nr_dept_nm  > 0.0000 THEN 'REJ-01: Null rate too high at department_name.  Exp=0.0000 / Act=' || CAST(nr_dept_nm AS VARCHAR2(8))
                    WHEN nr_mgr_id   > 0.6500 THEN 'REJ-02: Null rate too high at manager_id.  Exp<=0.6500 / Act=' || CAST(nr_mgr_id AS VARCHAR2(8))
                    WHEN nr_url      > 0.8000 THEN 'REJ-03: Null rate too high at url.  Exp<=0.8000 / Act=' || CAST(nr_url AS VARCHAR2(8))
                    ELSE 'P'
               END AS status
        FROM (
        	SELECT CAST(SUM(CASE WHEN department_name IS NULL THEN 1 ELSE 0 END) AS FLOAT(126)) / CAST(COUNT(*) AS FLOAT(126)) AS nr_dept_nm
                 , CAST(SUM(CASE WHEN manager_id      IS NULL THEN 1 ELSE 0 END) AS FLOAT(126)) / CAST(COUNT(*) AS FLOAT(126)) AS nr_mgr_id
                 , CAST(SUM(CASE WHEN url             IS NULL THEN 1 ELSE 0 END) AS FLOAT(126)) / CAST(COUNT(*) AS FLOAT(126)) AS nr_url
        	FROM demo_hr.departments
        )
    )
    
    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status 
    FROM dtls 
    WHERE status <> 'P';



-- T009 ------------------------------------------------------------------------------------------
-- "RS-3 Heuristics" #2 - Verify ValueFrequencyThresholds()" for [region_id] values (eg: value=1 for 28% to 36% of rows) in table [countries]

    WITH dtls AS (
        SELECT region_id, freq_rt
             , CASE WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.28 AND 0.36 THEN 'REJ-01: Frequency occurrence of region_id=1 is outside threshold|exp=0.28 thru 0.36|act=' || CAST(freq_rt AS VARCHAR2(8))
                    WHEN region_id = 2  AND freq_rt NOT BETWEEN 0.16 AND 0.24 THEN 'REJ-02: Frequency occurrence of region_id=2 is outside threshold|exp=0.16 thru 0.24|act=' || CAST(freq_rt AS VARCHAR2(8))
                    WHEN region_id = 3  AND freq_rt NOT BETWEEN 0.20 AND 0.28 THEN 'REJ-03: Frequency occurrence of region_id=3 is outside threshold|exp=0.20 thru 0.28|act=' || CAST(freq_rt AS VARCHAR2(8))
                    WHEN region_id = 4  AND freq_rt NOT BETWEEN 0.20 AND 0.28 THEN 'REJ-04: Frequency occurrence of region_id=4 is outside threshold|exp=0.20 thru 0.28|act=' || CAST(freq_rt AS VARCHAR2(8))
                    ELSE 'P'
               END AS status
        FROM (
            SELECT region_id, CAST(freq AS FLOAT(126)) / CAST(den AS FLOAT(126)) AS freq_rt
        	FROM (
        	    SELECT region_id, COUNT(*) AS freq
        	    , (SELECT COUNT(*) FROM demo_hr.countries) AS den
                FROM demo_hr.countries
                GROUP BY region_id
                )
        )
    )
    
    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status 
    FROM dtls 
    WHERE status <> 'P';
    


-- -----------------------------------------------------------------------------------------------
-- RULE SET #4: NUMERIC VALUES
-- -----------------------------------------------------------------------------------------------

-- T010 ------------------------------------------------------------------------------------------
-- "RS-4 Numeric" #1 - Verify NoNulls() at [region_id] in table [countries]

	SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
	FROM demo_hr.countries
	WHERE region_id IS NULL;


	
-- T011 ------------------------------------------------------------------------------------------
-- "RS-4 Numeric" #2 - Verify NotNegative() where [region_id] >= 0 in table [countries]

	SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
	FROM demo_hr.countries
	WHERE region_id < 0;


	
-- T012 ------------------------------------------------------------------------------------------
-- "RS-4 Numeric" #3 - Verify NumericRange() where [employee_id] between 100 and 999 in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT employee_id
             , CASE WHEN employee_id < 100   THEN 'REJ-01: Verify employee_id > 99|exp>99|act=' || CAST(employee_id AS VARCHAR2(10))
    	            WHEN employee_id > 999   THEN 'REJ-02: Verify employee_id < 1000|exp<1000|act=' || CAST(employee_id AS VARCHAR2(10))
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';



-- T013 ------------------------------------------------------------------------------------------
-- "RS-4 Numeric" #4 - Verify InValueList() where [region_id] is in list (1,2,3,4) at table [countries]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT region_id
             , CASE WHEN region_id NOT IN(1,2,3,4) THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    )
    WHERE status <> 'P';



-- T014 ------------------------------------------------------------------------------------------
-- "RS-4 Numeric" #5 - Verify NotInValueList() where [region_id] is not in list (97,98,99) at table [countries]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT region_id
             , CASE WHEN region_id IN(97,98,99) THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    )
    WHERE status <> 'P';



-- T015 ------------------------------------------------------------------------------------------
-- "RS-4 Numeric" #6 - Verify MultiFieldCompare() where [salary] x [commission_pct] <= $10,000 cap in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
        SELECT salary, commission_pct
             , CASE WHEN salary * commission_pct > 10000 THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';



-- -----------------------------------------------------------------------------------------------
-- RULE SET #5: DATE VALUES
-- -----------------------------------------------------------------------------------------------

-- T016 ------------------------------------------------------------------------------------------
-- "RS-5 Dates" #1 - Verify NoNulls() where [date_last_updated] has no nulls in table [countries]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT date_last_updated
             , CASE WHEN date_last_updated IS NULL THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    )
    WHERE status <> 'P';

	

-- T017 ------------------------------------------------------------------------------------------
-- "RS-5 Dates" #2 - Verify DateRange() where [date_last_updated] is not in the future nor too "old" at table [countries]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT date_last_updated
             , CASE WHEN date_last_updated > SYSDATE                             THEN 'REJ-01: Field date_last_updated cannot be in the future|exp<=' || CAST(SYSDATE AS VARCHAR2(20)) || '|act=' || CAST(date_last_updated AS VARCHAR2(20))
    	            WHEN date_last_updated < TO_DATE('01/01/2021', 'mm/dd/yyyy') THEN 'REJ-02: Field date_last_updated cannot be too old|exp>=1/1/2021|act=' || CAST(date_last_updated AS VARCHAR2(20))
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.countries
    )
    WHERE status <> 'P';



-- T018 ------------------------------------------------------------------------------------------
-- "RS-5 Dates" #3 - Verify NoTimePart() where [hire_date] has no time part (is "12:00:00") in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
        SELECT hire_date
             , CASE WHEN TO_CHAR(hire_date, 'hh:mi:ss') <> '12:00:00' THEN 'FAIL' ELSE 'P' END AS status
        FROM demo_hr.employees
    )
    WHERE status <> 'P';



-- T019 ------------------------------------------------------------------------------------------
-- "RS-5 Dates" #4 - Verify HasTimePart() where [hire_date] has time part (is not 12:00:00) at table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT start_tm
             , CASE WHEN TO_CHAR(start_tm, 'hh:mi:ss') = '12:00:00' THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.test_case_results
    )
    WHERE status <> 'P';


-- T020 ------------------------------------------------------------------------------------------
-- "RS-5 Dates" #5 - Verify MultiFieldCompare() where [start_date] must be < [end_date] in table [job_history]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
        SELECT start_date, end_date
             , CASE WHEN start_date >= end_date THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.job_history
    )
    WHERE status <> 'P';



-- -----------------------------------------------------------------------------------------------
-- RULE SET #6: TEXT VALUES
-- -----------------------------------------------------------------------------------------------

-- T021 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #01 - Verify NoNulls() where [country_name] has no nulls in table [countries]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT country_name
             , CASE WHEN country_name IS NULL THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    )
    WHERE status <> 'P';



-- T022 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #02 - Verify NoNullStrings() where space (Oracle does not support "" nullstring) in [country_name] at table [countries]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT country_name
             , CASE WHEN country_name = ' ' THEN 'FAIL' ELSE 'P'  END AS status
    	FROM demo_hr.countries
    )
    WHERE status <> 'P';


	
-- T023 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #03 - Verify NoLeadTrailSpaces() at [country_name] in table [countries]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT country_name
             , CASE WHEN country_name LIKE ' %'  THEN 'REJ-01: Verify no leading space at country_name|exp=noLeadSpace|act=''' || country_name ||''''
    				WHEN country_name LIKE '% '  THEN 'REJ-02: Verify no trailing space at country_name|exp=noTrailingSpace|act=''' || country_name ||''''
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.countries
    )
    WHERE status <> 'P';



-- T024 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #04 - Verify InValueList() where [job_id] is in list of valid values for table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT job_id
             , CASE WHEN job_id NOT IN('ST_MAN','ST_CLERK','SH_CLERK','SA_REP','SA_MAN','PU_CLERK','PR_REP','MK_REP','MK_MAN','IT_PROG'
                                      ,'HR_REP','FI_MGR','FI_ACCOUNT','AD_VP','AD_PRES','AD_ASST','AC_MGR','AC_ACCOUNT','PU_MAN')
                    THEN 'FAIL'
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';



-- T025 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #05 - Verify NotInValueList() where [job_id] not in list of invalid values at table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT job_id
             , CASE WHEN job_id IN('CEO','CFO','COO','CIO','POTUS') THEN 'FAIL'  ELSE 'P'  END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T026 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #06 - Verify MultiFieldCompare() where [email] = first letter of [first_name] + [last_name] in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT email, first_name, last_name
             , CASE WHEN email <> SUBSTR(UPPER(SUBSTR(first_name, 1, 1) || last_name), 1, 8) THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    	WHERE email NOT IN('DRAPHEAL', 'JAMRLOW', 'JMURMAN', 'LDEHAAN', 'JRUSSEL', 'TJOLSON')  
    	                 -- DRAPHAEL vs DRAPHEAL, JMARLOW vs JAMRLOW, JMURMAN vs JURMAN, LDE HAAN VS LDEHAAN, JRUSSELL vs JRUSSEL, TOLSON vs TJOLSON 
    )
    WHERE status <> 'P';



-- T027 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #07 - Verify TextLength() where [phone_number] length is 12 or 18 characters in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT phone_number
             , CASE WHEN LENGTH(phone_number) NOT IN(112,18)  THEN 'REJ-01: Verify phone_number length is allowed|exp=112,18|act=' || LENGTH(phone_number)
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';



-- T028 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #08 - Verify UpperLowerCaseChars() where [lastname] has all LCase after first character and [job_id] is all UCase in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT job_id, last_name
             , CASE WHEN REGEXP_LIKE(job_id, '[[:lower:]]')                  THEN 'REJ-01: Verify job_id does not contain lower case characters|exp=ucase|act=' || job_id
    	            WHEN NOT REGEXP_LIKE(SUBSTR(last_name,1), '[[:upper:]]') THEN 'REJ-02: Verify last_name after first char is all lower case|exp=lcase|act=' || last_name 
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';

	

-- T029 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #09 - Verify AlphaNumericChars() where [employee_id] is numeric, and [lastname] is alpha in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT employee_id, last_name
             , CASE WHEN REGEXP_LIKE(employee_id, '[[:alpha:]]')   THEN 'REJ-01: Verify employee_id does not contain alpha characters|exp=no-alphas|act=' || EMPLOYEE_ID
                    WHEN REGEXP_LIKE(last_name, '[[:digit:]]')     THEN 'REJ-02: Verify last_name does not contain numeric digits|exp=no-digits|act=' || LAST_NAME 
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T030 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #10 - Verify No_Quote_Chars() where [first_name] has no quotes or apostrophes in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT first_name
             , CASE WHEN first_name LIKE '%''%'  THEN 'REJ-01: Verify first_name does not contain single quote characters|exp=none|act=' || first_name
                    WHEN first_name LIKE '%"%'   THEN 'REJ-02: Verify first_name does not contain quotation characters|exp=none|act=' || first_name
                    ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T031 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #11 - Verify No_CRLF_Chars() where [last_name] has no Carriage Returns (CHAR-13) or Line Feeds (CHAR-10) in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
        SELECT last_name
             , CASE WHEN INSTR(last_name, CHR(10))  > 0 THEN 'REJ-01: Field last_name has a Line Feed (CHR-10)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(10)) AS VARCHAR2(4))
    	            WHEN INSTR(last_name, CHR(13))  > 0 THEN 'REJ-02: Field last_name has a Carriage Return (CHR-13)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(13)) AS VARCHAR2(4))
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T032 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #12 - Verify No_TAB_Chars() where [last_name] has no TAB characters (CHAR-9) in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT last_name
             , CASE WHEN INSTR(last_name, CHR(9)) > 0 THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T033 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #13 - Verify No_NBS_Chars() where [last_name] has no Non-Breaking-Spaces (CHAR-160) in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT last_name
             , CASE WHEN INSTR(last_name, CHR(160)) > 0 THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T034 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #14 - Verify No_EmDash_Chars() where [last_name] has an EmDash character (CHAR-151...common Microsoft Word "--" conversion causing data load issues) in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT last_name
             , CASE WHEN INSTR(last_name, CHR(151)) > 0 THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T035 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #15 - Verify No_VTFFNEL_Chars() where [last_name] has Vertical Tabs (CHAR-11), Form Feeds (CHAR-12) or Next Lines (CHAR-133) in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT last_name
             , CASE WHEN INSTR(last_name, CHR(11)) > 0  THEN 'REJ-01: Field last_name has a Vertical Tab (CHR-11)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(11)) AS VARCHAR2(4))
    	            WHEN INSTR(last_name, CHR(12)) > 0  THEN 'REJ-02: Field last_name has a Form Feed (CHR-12)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(12)) AS VARCHAR2(4))
    	            WHEN INSTR(last_name, CHR(133)) > 0 THEN 'REJ-03: Field last_name has a Next Line (CHR-133)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(133)) AS VARCHAR2(4))
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T036 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #16 - Verify No_PeriodDash_Chars() where [last_name] has periods or dashes in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT last_name
             , CASE WHEN INSTR(last_name, '.') > 0 OR INSTR(last_name, '-') > 0 THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T037 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #17 - Verify NoBadChars() where [last_name] has no funky punctuation ",/:()&#?;" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT last_name
             , CASE WHEN REGEXP_LIKE(last_name, '[,/:()&#?;]') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T038 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #18 - Verify OnlyAllowedChars() where [phone_number] only has characters ".0123456789" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT phone_number
             , CASE WHEN REGEXP_LIKE(phone_number, '[^.0123456789]') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';



-- T039 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #19 - Verify LikeWildcards() where [phone_number] contains a ''.'' and matches valid patterns in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT phone_number
             , CASE WHEN phone_number NOT LIKE '%.%'                THEN 'REJ-01: Verify phone_number contains a ''.''|exp=contains-.|act=' || phone_number
                    WHEN phone_number NOT LIKE '___.___.____' 
                     AND phone_number NOT LIKE '011.__.____._____%' THEN 'REJ-02: Verify phone_number like pattern "___.___.____" or "011.__.____._____"|exp=yes|act=' || phone_number
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T040 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #20 - Verify IsNumeric() where [zip5] will convert to numeric in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT zip5
             , CASE WHEN NOT REGEXP_LIKE(zip5, '^\d+(\.\d+)?$') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T041 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #21 - Verify IsDate("yyyymmdd") where [some_date_fmt1] has date fmt="yyyymmd" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT some_date_fmt1
             , CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        some_date_fmt1,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9','')
                        > ''                                                      THEN 'REJ-01: Unexpected chars exist (numeric 0-9 only)|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
                    WHEN NOT LENGTH(TRIM(some_date_fmt1)) = 8                     THEN 'REJ-02: Must be 8 Chars|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
                    WHEN NOT SUBSTR(some_date_fmt1,1,4) BETWEEN '1753' AND '9999' THEN 'REJ-03: Year Not Btw 1753-9999|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
                    WHEN NOT SUBSTR(some_date_fmt1,5,2) BETWEEN '01' AND '12'     THEN 'REJ-04: Month Not Btw 01-12|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
                    WHEN NOT SUBSTR(some_date_fmt1,7,2) BETWEEN '01' AND '31'     THEN 'REJ-05: Day Not Btw 01-31|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
                    ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T042 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #22 - Verify IsDate("mm/dd/yyyy") where [some_date_fmt2] has date fmt="mm/dd/yyyy" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT some_date_fmt2
             , CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                         some_date_fmt2,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'/','')
                         > ''                                                    THEN 'REJ-01: Unexpected Chars Exist|exp=Fmt="mm/dd/yyyy"|act=' || some_date_fmt2
                   WHEN NOT LENGTH(TRIM(some_date_fmt2)) = 10                    THEN 'REJ-02: Must be 10 Chars|exp=Fmt="mm/dd/yyyy"|act=' || some_date_fmt2
                   WHEN NOT SUBSTR(some_date_fmt2,7,4) BETWEEN '1753' AND '9999' THEN 'REJ-03: Year Not Btw 1753-9999|exp=Fmt="mm/dd/yyyy"|act=' || some_date_fmt2
                   WHEN NOT SUBSTR(some_date_fmt2,1,2) BETWEEN '01' AND '12'     THEN 'REJ-04: Month Not Btw 01-12|exp=Fmt="mm/dd/yyyy"|act=' || some_date_fmt2
                   WHEN NOT SUBSTR(some_date_fmt2,4,2) BETWEEN '01' AND '31'     THEN 'REJ-05: Day Not Btw 01-31|exp=Fmt="mm/dd/yyyy"|act=' || some_date_fmt2
                   ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T043 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #23 - Verify IsDate("mm-dd-yyyy") where [some_date_fmt3] has date fmt="mm-dd-yyyy" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT some_date_fmt3
             , CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                         some_date_fmt3,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'-','')
                         > ''                                                    THEN 'REJ-01: Unexpected Chars Exist|exp=Fmt="mm-dd-yyyy"|act=' || some_date_fmt3
                   WHEN NOT LENGTH(TRIM(some_date_fmt3)) = 10                    THEN 'REJ-02: Must be 10 Chars|exp=Fmt="mm-dd-yyyy"|act=' || some_date_fmt3
                   WHEN NOT SUBSTR(some_date_fmt3,7,4) BETWEEN '1753' AND '9999' THEN 'REJ-03: Year Not Btw 1753-9999|exp=Fmt="mm-dd-yyyy"|act=' || some_date_fmt3
                   WHEN NOT SUBSTR(some_date_fmt3,1,2) BETWEEN '01' AND '12'     THEN 'REJ-04: Month Not Btw 01-12|exp=Fmt="mm-dd-yyyy"|act=' || some_date_fmt3
                   WHEN NOT SUBSTR(some_date_fmt3,4,2) BETWEEN '01' AND '31'     THEN 'REJ-05: Day Not Btw 01-31|exp=Fmt="mm-dd-yyyy"|act=' || some_date_fmt3
                   ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T044 ------------------------------------------------------------------------------------------
-- "RS-6 Text" #24 - Verify IsDate("yyyy-mm-dd") where [some_date_fmt4] has date fmt="yyyy-mm-dd" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT some_date_fmt4
             , CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        some_date_fmt4,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'-','')
                        > ''                                                     THEN 'REJ-01: Unexpected Chars Exist|exp=Fmt="yyyy-mm-dd"|act=' || some_date_fmt4
                   WHEN NOT LENGTH(TRIM(some_date_fmt4)) = 10                    THEN 'REJ-02: Must be 10 Chars|exp=Fmt="yyyy-mm-dd"|act=' || some_date_fmt4
                   WHEN NOT SUBSTR(some_date_fmt4,1,4) BETWEEN '1753' AND '9999' THEN 'REJ-03: Year Not Btw 1753-9999|exp=Fmt="yyyy-mm-dd"|act=' || some_date_fmt4
                   WHEN NOT SUBSTR(some_date_fmt4,6,2) BETWEEN '01' AND '12'     THEN 'REJ-04: Month Not Btw 01-12|exp=Fmt="yyyy-mm-dd"|act=' || some_date_fmt4
                   WHEN NOT SUBSTR(some_date_fmt4,9,2) BETWEEN '01' AND '31'     THEN 'REJ-05: Day Not Btw 01-31|exp=Fmt="yyyy-mm-dd"|act=' || some_date_fmt4
                   ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';



-- -----------------------------------------------------------------------------------------------
-- RULE SET #7: REGULAR EXPRESSIONS
-- -----------------------------------------------------------------------------------------------

-- T045 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #01 - Verify RegExp("IsPhoneNumber") where phone_number matches RegEx pattern "[0-9]{3}[-. ][0-9]{3}[-. ][0-9]{4}" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
        -- NOTE: Use RegEx pattern "^\+(\d+\s?)+$" for international phone numbers
        SELECT phone_number
             , CASE WHEN NOT REGEXP_LIKE(phone_number, '[0-9]{3}[-. ][0-9]{3}[-. ][0-9]{4}') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T046 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #02 - Verify RegExp("IsSSN") where [fake_ssn] matches RegEx pattern "^[0-9]{3}-[0-9]{2}-[0-9]{4}$" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT fake_ssn
             , CASE WHEN NOT REGEXP_LIKE(fake_ssn, '^[0-9]{3}-[0-9]{2}-[0-9]{4}$') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T047 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #03 - Verify RegExp("IsZip5") where [zip5] matches RegEx pattern "^[0-9]{5}$" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT zip5
             , CASE WHEN NOT REGEXP_LIKE(zip5, '^[0-9]{5}$') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T048 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #04 - Verify RegExp("IsZip5or9") where [zip5or9] matches RegEx pattern "^[[:digit:]]{5}(-[[:digit:]]{4})?$" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT zip5or9
             , CASE WHEN NOT REGEXP_LIKE(zip5or9, '^[[:digit:]]{5}(-[[:digit:]]{4})?$') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T049 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #05 - Verify RegExp("IsZip9") where [zip9] matches RegEx pattern "^[[:digit:]]{5}[-/.][[:digit:]]{4}$" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT zip9
             , CASE WHEN NOT REGEXP_LIKE(zip9, '^[[:digit:]]{5}[-/.][[:digit:]]{4}$') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T050 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #06 - Verify RegExp("OnlyText") where [last_name] matches RegEx pattern "^[a-zA-Z ]+$" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT last_name
             , CASE WHEN NOT REGEXP_LIKE(last_name, '^[a-zA-Z ]+$') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T051 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #07 - Verify RegExp("OnlyNumeric") where [zip5] matches RegEx pattern "^[0-9]+$" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT zip5
             , CASE WHEN NOT REGEXP_LIKE(zip5, '^[0-9]+$') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T052 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #08 - Verify RegExp("NoLeadTrailSpaces") where [last_name] matches RegEx pattern "(^\s)|(\s$)" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT last_name
             , CASE WHEN REGEXP_LIKE(last_name, '(^\s)|(\s$)') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T053 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #09 - Verify RegExp("NoWhitespaces") where [job_id] matches RegEx pattern "(\s)+" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT job_id
             , CASE WHEN REGEXP_LIKE(job_id, '(\s)+') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T054 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #10 - Verify RegExp("OnlyLowerCase") at 3rd and 4th chars of [first_name] matching RegEx pattern "^[a-z]+$" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT first_name
             , CASE WHEN NOT REGEXP_LIKE(SUBSTR(first_name,3,2), '^[a-z]+$') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T055 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #11 - Verify RegExp("OnlyUpperCase") where [email] matching RegEx pattern "^[A-Z]+$" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT email
             , CASE WHEN NOT REGEXP_LIKE(SUBSTR(email,3,2), '^[A-Z]+$') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T056 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #12 - Verify RegExp("TitleCase") where [first_name] upper cases first letter second name too and matches RegEx pattern "(\s[A-Z]){1}" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT first_name, SUBSTR(first_name,1,1) AS first_letter
             , CASE WHEN NOT REGEXP_LIKE(SUBSTR(first_name,1,1), '([A-Z])') THEN 'REJ-01: Field first_name first character not upper case|exp=Like"[A-Z]"|act=' || first_name 
                    WHEN first_name NOT LIKE '% %'                          THEN 'P'  -- Only one word, so no space + first character to check for uppercase
                    WHEN NOT REGEXP_LIKE(first_name, '(\s[A-Z]){1}')        THEN 'REJ-02: Field first_name failed RegExpression check|exp=Like"(\s[A-Z]){1}"|act=' || first_name 
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';


-- T057 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #13 - Verify RegExp("EmailAddress") where [email_address] matches RegEx pattern "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$" in table [employees]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT email_address
             , CASE WHEN NOT REGEXP_LIKE(email_address, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.employees
    )
    WHERE status <> 'P';



-- T058 ------------------------------------------------------------------------------------------
-- "RS-7 RegEx" #14 - Verify RegExp("IsUrl") where [url] matches RegEx pattern "(http)(s)?(:\/\/)" in table [departments]

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT url
             , CASE WHEN NOT REGEXP_LIKE(url, '(http)(s)?(:\/\/)') THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.departments
    )
    WHERE status <> 'P';




-- -----------------------------------------------------------------------------------------------
-- RULE SET #8: DIFF CHECKS
-- -----------------------------------------------------------------------------------------------

-- T059 ------------------------------------------------------------------------------------------
-- "RS-8 Diffs" #1 - Verify TableStructure("BySQL") by comparing snapshot in SQL code vs actual schema/structure for table [locations]

    WITH expected 
    AS (
    	      SELECT 1 AS ord_pos, 'LOCATION_ID'    AS column_nm, 'NUMBER(4)'    AS data_typ, 'NOT NULL' AS nullable FROM dual
    	UNION SELECT 2 AS ord_pos, 'STREET_ADDRESS' AS column_nm, 'VARCHAR2(40)' AS data_typ, 'NULL' AS nullable FROM dual
    	UNION SELECT 3 AS ord_pos, 'POSTAL_CODE'    AS column_nm, 'VARCHAR2(12)' AS data_typ, 'NULL' AS nullable FROM dual
    	UNION SELECT 4 AS ord_pos, 'CITY'           AS column_nm, 'VARCHAR2(30)' AS data_typ, 'NOT NULL' AS nullable FROM dual
    	UNION SELECT 5 AS ord_pos, 'STATE_PROVINCE' AS column_nm, 'VARCHAR2(25)' AS data_typ, 'NULL' AS nullable FROM dual
    	UNION SELECT 6 AS ord_pos, 'COUNTRY_ID'     AS column_nm, 'CHAR(2)'      AS data_typ, 'NULL' AS nullable FROM dual
    	ORDER BY ord_pos
    )
    , actual
    AS (
    	SELECT
    	  atc.column_id   AS ord_pos
    	, atc.column_name AS column_nm 
    	, (atc.data_type ||
    	    decode(atc.data_type,
    	      'NUMBER',
    	         decode(atc.data_precision, null, '',
    	          '(' || to_char(atc.data_precision) || decode(atc.data_scale,null,'',0,'',',' || to_char(atc.data_scale) )
    	              || ')' ),
    	      'FLOAT', '(' || to_char(atc.data_precision) || ')',
    	      'VARCHAR2', '(' || to_char(atc.data_length) || ')',
    	      'NVARCHAR2', '(' || to_char(atc.data_length) || ')',
    	      'VARCHAR', '(' || to_char(atc.data_length) || ')',
    	      'CHAR', '(' || to_char(atc.data_length) || ')',
    	      'RAW', '(' || to_char(atc.data_length) || ')',
    	      'MLSLABEL',decode(atc.data_length,null,'',0,'','(' || to_char(atc.data_length) || ')'),
    	      '')
    	  )                 AS data_typ
    	, CASE WHEN atc.nullable = 'Y' THEN 'NULL' ELSE 'NOT NULL' END AS nullable
    	FROM       all_tab_columns  atc
    	INNER JOIN all_col_comments dcc ON atc.owner = dcc.owner AND atc.table_name = dcc.table_name AND atc.column_name = dcc.column_name
    	INNER JOIN all_tab_comments t   ON t.OWNER = atc.owner   AND t.TABLE_NAME = atc.table_name
    	WHERE atc.owner = 'DEMO_HR'
    	  AND atc.table_name = 'LOCATIONS'
    )
    , dut -- Data Under Test 
    AS (
    	SELECT CASE WHEN (SELECT COUNT(*) FROM actual) = 0 THEN 'REJ-01: Table [locations] does not exist (may be case sensistive name)|exp=exists|act=notExist' 
    	            WHEN a.column_nm IS NULL               THEN 'REJ-01: Expected column is missing from actual schema (may be case sensitive name)|exp=' || e.column_nm || '|act=IsMissing' 
    	            WHEN a.ord_pos <> e.ord_pos            THEN 'REJ-02: Ordinal Positions at field ' || e.column_nm || ' do not match|exp=' || CAST(e.ord_pos AS VARCHAR2(3)) || '|act=' || CAST(a.ord_pos AS VARCHAR2(3))
    	            WHEN a.data_typ <> e.data_typ          THEN 'REJ-03: Data Types at field ' || e.column_nm || ' do not match|exp=' || e.data_typ || '|act=' || a.data_typ 
    	            WHEN a.nullable <> e.nullable          THEN 'REJ-04: Nullable settings at field ' || e.column_nm || ' do not match|exp=' || e.nullable || '|act=' || a.nullable 
    	            ELSE 'P'
    	       END AS status
    	FROM      expected e 
    	LEFT JOIN actual   a ON a.column_nm = e.column_nm
    )

    SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END status
    FROM dut WHERE status <> 'P';
    
    


-- T060 ------------------------------------------------------------------------------------------
-- "RS-8 Diffs" #2 - Verify TableData("BySQL") - Data should not change for table [regions]

    WITH metadata 
    AS (
    	      SELECT 1 AS region_id, 'Europe' AS region_name FROM dual
    	UNION SELECT 2 AS region_id, 'Americas' AS region_name FROM dual
    	UNION SELECT 3 AS region_id, 'Asia' AS region_name FROM dual
    	UNION SELECT 4 AS region_id, 'Middle East and Africa' AS region_name FROM dual
    	ORDER BY region_id
    )
    , dut -- Data Under Test 
    AS (
    	SELECT CASE WHEN r.region_id IS NULL            THEN 'REJ-01: Record is missing from metadata|exp=NotMissing|act=' || m.region_id || ' is missing' 
    	            WHEN r.region_name <> m.region_name THEN 'REJ-02: Region_Name does not match|exp=' || m.region_name || '|act=' || r.region_name 
    	            ELSE 'P'
    	       END AS status
    	FROM      metadata   m 
    	LEFT JOIN demo_hr.regions r ON r.region_id = m.region_id
    	ORDER BY m.region_id
    )
    
    SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END status
    FROM dut WHERE status <> 'P';





-- T061 ------------------------------------------------------------------------------------------
-- "RS-8 Diffs" #3 - Verify TableData("By2TableCompare") - Table data should exactly match between tables [jobs] and [jobs_snapshot]

    WITH non_matches
    AS (
        SELECT MAX(tbl_nm) AS tbl_nm, job_id, job_title, min_salary, max_salary, COUNT(*) AS match_count_found
        FROM (
    		SELECT CAST('jobs' AS VARCHAR2(15)) AS tbl_nm,          job_id, job_title, min_salary, max_salary FROM demo_hr.JOBS  
    		UNION ALL 
    		SELECT CAST('jobs_snapshot' AS VARCHAR2(15)) AS tbl_nm, job_id, job_title, min_salary, max_salary FROM demo_hr.JOBS_SNAPSHOT 
        ) comb_sets 
        GROUP BY job_id, job_title, min_salary, max_salary
        HAVING COUNT(*) < 2
    )
    , dut -- Data Under Test 
    AS (
    	SELECT 'REJ-01: Mismatch Found: tbl_nm="' || tbl_nm ||'", job_id="' || job_id || '", job_title="' || job_title 
    	    || '", min_salary=' || CAST(min_salary AS VARCHAR2(20)) || '", max_salary=' || CAST(max_salary AS VARCHAR2(20)) AS status
    	FROM      non_matches  
    	ORDER BY 1
    )

    SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END status
    FROM dut WHERE status <> 'P'
;



-- -----------------------------------------------------------------------------------------------
-- RULE SET #9: DEFECT REGRESSION
-- -----------------------------------------------------------------------------------------------

-- This is where you would add on SQL validations (where appropriate) that regression test defects
-- that come up over time.  Most will take the form of one of the example test cases above.




-- -----------------------------------------------------------------------------------------------
-- BEST PRACTICES: 
-- -----------------------------------------------------------------------------------------------

-- T062 ------------------------------------------------------------------------------------------
-- "X#1 WarnSkip" - Verify ValueFrequencyThresholds()" for [region_id] values (eg: value=1 for 28% to 36% of rows) in table [countries]

    WITH dut -- data under test
    AS (
    	SELECT region_id
    	, CAST(freq AS FLOAT(126)) / CAST(den AS FLOAT(126)) AS freq_rt
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
             , CASE WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.10 AND 0.50 then 'FAIL: Frequency occurrence of region_id=1 is FAR outside threshold|exp=0.28 thru 0.36|act=' || CAST(freq_rt AS VARCHAR2(8))
                    WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.25 AND 0.35 then 'WARN: Frequency occurrence of region_id=1 is outside threshold|exp=0.20 thru 0.28|act=' || CAST(freq_rt AS VARCHAR2(8))
                    ELSE 'P'
    	       END AS status
    	FROM dut
    )
	-- SELECT * FROM bll;
    
    SELECT CASE WHEN (SELECT COUNT(*) FROM bll) = 0 THEN 'SKIP'
	            WHEN (SELECT COUNT(*) FROM bll WHERE status LIKE 'FAIL:%') > 0 THEN 'FAIL'
	            WHEN (SELECT COUNT(*) FROM bll WHERE status LIKE 'WARN:%') > 0 THEN 'WARN'
	            ELSE 'P'
	       END AS status
    FROM dual;

 

-- T063 ------------------------------------------------------------------------------------------
-- "X#2 LimitToRecent" - VerVerify NoNulls() at [region_id] in table [countries] for past 30 days

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT region_id, date_last_updated
             , CASE WHEN region_id IS NULL  THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    	WHERE date_last_updated >= SYSDATE - 30 
    )
    WHERE status <> 'P';



-- T064 ------------------------------------------------------------------------------------------
-- "X#3 IgnoreBadRows" - Verify NoNulls() at [region_id] in table [countries]; ignoring 3 known bad rows

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
    	SELECT region_id, country_id
             , CASE WHEN region_id IS NULL  THEN 'FAIL' ELSE 'P' END AS status
    	FROM demo_hr.countries
    	WHERE country_id NOT IN('BR','DK','IL') 
    )
    WHERE status <> 'P';



-- T065 ------------------------------------------------------------------------------------------
-- "X#4 TableScan" - Verify dozens of checks in a single table scan pass against table [employees] for best performance

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
        SELECT employee_id, salary, commission_pct, hire_date, zip5, job_id, email, first_name, last_name, phone_number, some_date_fmt1
             , CASE WHEN employee_id < 100                                        THEN 'REJ-01: Field employee_id > 99|exp>99|act=' || CAST(employee_id AS VARCHAR2(10))
    	            WHEN employee_id > 999                                        THEN 'REJ-02: Field employee_id < 1000|exp<1000|act=' || CAST(employee_id AS VARCHAR2(10))
    	            WHEN salary * commission_pct > 10000                          THEN 'REJ-03: Fields salary x commission_pct <= $10,000|exp<10,000|act=' || CAST(salary * commission_pct AS VARCHAR2(15))
    				WHEN TO_CHAR(hire_date, 'hh:mi:ss') <> '12:00:00'             THEN 'REJ-04: Field hire_date cannot have a time part|exp=12:00:00|act=' || TO_CHAR(hire_date, 'hh:nn:ss')
                    WHEN NOT REGEXP_LIKE(zip5, '^[0-9]+$')                        THEN 'REJ-05: Field zip5 failed RegExpression check|exp=Like"^[0-9]+$"|act=' || zip5 
    	            WHEN job_id IN('CEO','CFO','COO','CIO','POTUS')               THEN 'REJ-06: Verify job_id not in domain list of excluded values|exp<>1of5|act=' || job_id
    	            WHEN email <> SUBSTR(UPPER(SUBSTR(
    	                            first_name, 1, 1) || last_name), 1, 8)        THEN 'REJ-07: Field email <> first char of first_name + last_name|exp=' || SUBSTR(UPPER(SUBSTR(first_name, 1, 1) || last_name), 1, 8) || '|act=' || email
    	            WHEN LENGTH(phone_number) NOT IN(12,18)                       THEN 'REJ-08: Field phone_number length is allowed|exp=12,18|act=' || LENGTH(phone_number)
    	            WHEN REGEXP_LIKE(job_id, '[[:lower:]]')                       THEN 'REJ-09: Field job_id does not contain lower case characters|exp=ucase|act=' || EMAIL
    	            WHEN NOT REGEXP_LIKE(SUBSTR(last_name,1), '[[:upper:]]')      THEN 'REJ-10: Field last_name after first char is all lower case|exp=lcase|act=' || LAST_NAME 
    	            WHEN REGEXP_LIKE(employee_id, '[[:alpha:]]')                  THEN 'REJ-11: Field employee_id does not contain alpha characters|exp=no-alphas|act=' || EMPLOYEE_ID
                    WHEN REGEXP_LIKE(last_name, '[[:digit:]]')                    THEN 'REJ-12: Field last_name does not contain numeric digits|exp=no-digits|act=' || LAST_NAME 
    	            WHEN first_name LIKE '%''%'                                   THEN 'REJ-13: Field first_name does not contain single quote characters|exp=none|act=' || first_name
                    WHEN first_name LIKE '%"%'                                    THEN 'REJ-14: Field first_name does not contain quotation characters|exp=none|act=' || first_name
                    WHEN INSTR(last_name, CHR(10))  > 0                           THEN 'REJ-15: Field last_name has a Line Feed (CHR-10)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(10)) AS VARCHAR2(4))
    	            WHEN INSTR(last_name, CHR(13))  > 0                           THEN 'REJ-16: Field last_name has a Carriage Return (CHR-13)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(13)) AS VARCHAR2(4))
    	            WHEN INSTR(last_name, CHR(9))   > 0                           THEN 'REJ-17: Field last_name has a Tab (CHR-9)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(9)) AS VARCHAR2(4))
    	            WHEN INSTR(last_name, CHR(160)) > 0                           THEN 'REJ-18: Field last_name has a Non-Breaking-Space (CHR-160)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(160)) AS VARCHAR2(4))
    	            WHEN INSTR(last_name, CHR(151)) > 0                           THEN 'REJ-19: Field last_name has a Non-Breaking-Space (CHR-151)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(151)) AS VARCHAR2(4))
    	            WHEN INSTR(last_name, CHR(11)) > 0                            THEN 'REJ-20: Field last_name has a Vertical Tab (CHR-11)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(11)) AS VARCHAR2(4))
    	            WHEN INSTR(last_name, CHR(12)) > 0                            THEN 'REJ-21: Field last_name has a Form Feed (CHR-12)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(12)) AS VARCHAR2(4))
    	            WHEN INSTR(last_name, CHR(133)) > 0                           THEN 'REJ-22: Field last_name has a Next Line (CHR-133)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(133)) AS VARCHAR2(4))
    	            WHEN INSTR(last_name, '.') > 0                                THEN 'REJ-23: Field last_name has a period|exp=none|act=at position ' || CAST(INSTR(last_name, '.') AS VARCHAR2(4))
    	            WHEN REGEXP_LIKE(last_name, '[,/:()&#?;]')                    THEN 'REJ-24: Field last_name has a ",/:()&#?;" characters|exp=none|act=' || last_name 
    	            WHEN REGEXP_LIKE(phone_number, '[^.0123456789]')              THEN 'REJ-25: Field phone_number can only have characters ".012345789"|exp=onlyAlloweChars|act=' || phone_number 
    	            WHEN phone_number NOT LIKE '%.%'                              THEN 'REJ-26: Verify phone_number contains a ''.''|exp=contains-.|act=' || phone_number
                    WHEN phone_number NOT LIKE '___.___.____' 
                     AND phone_number NOT LIKE '011.__.____._____%'               THEN 'REJ-27: Verify phone_number like pattern "___.___.____" or "011.__.____._____"|exp=yes|act=' || phone_number
    	            WHEN NOT REGEXP_LIKE(zip5, '^\d+(\.\d+)?$')                   THEN 'REJ-28: Field zip9 will not convert to a number|exp=converts to number|act=' || zip5 
    	            WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    	                 REPLACE(REPLACE(REPLACE(some_date_fmt1,'0',''),'1','')
    	                 ,'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8'
    	                 ,''),'9','')  > ''                                       THEN 'REJ-29: Unexpected chars exist (numeric 0-9 only)|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
                    WHEN NOT LENGTH(TRIM(some_date_fmt1)) = 8                     THEN 'REJ-30: Must be 8 Chars|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
                    WHEN NOT SUBSTR(some_date_fmt1,1,4) BETWEEN '1753' AND '9999' THEN 'REJ-31: Year Not Btw 1753-9999|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
                    WHEN NOT SUBSTR(some_date_fmt1,5,2) BETWEEN '01' AND '12'     THEN 'REJ-32: Month Not Btw 01-12|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
                    WHEN NOT SUBSTR(some_date_fmt1,7,2) BETWEEN '01' AND '31'     THEN 'REJ-33: Day Not Btw 01-31|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
    	            ELSE 'P'
    	       END AS status
    	FROM demo_hr.employees
        WHERE email NOT IN('DRAPHEAL', 'JAMRLOW', 'JMURMAN', 'LDEHAAN', 'JRUSSEL', 'TJOLSON')  
    	               -- DRAPHAEL vs DRAPHEAL, JMARLOW vs JAMRLOW, JMURMAN vs JURMAN, LDE HAAN VS LDEHAAN, JRUSSELL vs JRUSSEL, TOLSON vs TJOLSON)
    )
    WHERE status <> 'P';



-- T066 ------------------------------------------------------------------------------------------
-- "X#5 ConfigTbl" - Reference configuration settings from a temporary lookup table

    SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
    FROM (
        SELECT CASE WHEN row_count < 5 THEN 'FAIL'
                    ELSE 'P'
               END AS status
        FROM (
            SELECT COUNT(*) AS row_count 
            FROM demo_hr.countries
            WHERE date_last_updated >= SYSDATE - (SELECT CAST(prop_val AS INT) 
                                                  FROM demo_hr.test_case_config 
                                                  WHERE prop_nm = 'NumberDaysLookBack')
        )
    )
    WHERE status <> 'P';


