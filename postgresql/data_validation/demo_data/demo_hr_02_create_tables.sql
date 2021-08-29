
-- demo_hr.jobs definition
CREATE TABLE demo_hr.jobs 
   (job_id VARCHAR(10), 
	job_title VARCHAR(35) CONSTRAINT job_title_nn NOT NULL, 
	min_salary INTEGER, 
	max_salary INTEGER, 
	 CONSTRAINT job_id_pk PRIMARY KEY (job_id)
   );



-- demo_hr.jobs_snapshot definition
CREATE TABLE demo_hr.jobs_snapshot 
   (job_id VARCHAR(10), 
	job_title VARCHAR(35) NOT NULL,
	min_salary INTEGER, 
	max_salary INTEGER
   );


  
-- demo_hr.regions definition
CREATE TABLE demo_hr.regions 
   (region_id INTEGER CONSTRAINT region_id_nn NOT NULL, 
	region_name VARCHAR(25), 
	 CONSTRAINT reg_id_pk PRIMARY KEY (region_id)
   );



-- demo_hr.countries definition
CREATE TABLE demo_hr.countries 
   (country_id CHAR(2) CONSTRAINT country_id_nn NOT NULL, 
	country_name VARCHAR(40), 
	region_id INTEGER, 
	date_last_updated DATE DEFAULT CURRENT_DATE, 
	 CONSTRAINT country_c_id_pk PRIMARY KEY (country_id), 
	 CONSTRAINT countr_reg_fk FOREIGN KEY (region_id) REFERENCES demo_hr.regions (region_id)
   );




-- demo_hr.locations definition
CREATE TABLE demo_hr.locations
   (location_id INTEGER, 
	street_address VARCHAR(40), 
	postal_code VARCHAR(12), 
	city VARCHAR(30) CONSTRAINT loc_city_nn NOT NULL, 
	state_province VARCHAR(25), 
	country_id CHAR(2), 
	 CONSTRAINT loc_id_pk PRIMARY KEY (location_id), 
	 CONSTRAINT loc_c_id_fk FOREIGN KEY (country_id) REFERENCES demo_hr.countries (country_id)
   );

CREATE INDEX loc_city_ix ON demo_hr.locations (city);
CREATE INDEX loc_state_province_ix ON demo_hr.locations (state_province);
CREATE INDEX loc_country_ix ON demo_hr.locations (country_id);



-- demo_hr.departments dEFinition
CREATE TABLE demo_hr.departments 
   (department_id INTEGER, 
	department_name VARCHAR(30) CONSTRAINT dept_name_nn NOT NULL, 
	manager_id INTEGER, 
	location_id INTEGER, 
	url VARCHAR(255), 
	CONSTRAINT dept_id_pk PRIMARY KEY (department_id), 
	CONSTRAINT dept_loc_fk FOREIGN KEY (location_id) REFERENCES demo_hr.locations (location_id) 
   ) ;

CREATE INDEX dept_location_ix ON demo_hr.departments (location_id);



-- demo_hr.job_history definition
CREATE TABLE demo_hr.job_history 
   (employee_id INTEGER CONSTRAINT jhist_employee_nn NOT NULL, 
	start_date DATE CONSTRAINT jhist_start_date_nn NOT NULL, 
	end_date DATE CONSTRAINT jhist_end_date_nn NOT NULL, 
	job_id VARCHAR(10) CONSTRAINT jhist_job_nn NOT NULL, 
	department_id INTEGER, 
	 CONSTRAINT jhist_date_interval CHECK (end_date > start_date), 
	 CONSTRAINT jhist_emp_id_st_date_pk PRIMARY KEY (employee_id, start_date), 
	 CONSTRAINT jhist_job_fk FOREIGN KEY (job_id) REFERENCES demo_hr.jobs (job_id), 
	 CONSTRAINT jhist_dept_fk FOREIGN KEY (department_id) REFERENCES demo_hr.departments (department_id)
   ) ;

CREATE INDEX jhist_job_ix ON demo_hr.job_history (job_id);
CREATE INDEX jhist_employee_ix ON demo_hr.job_history (employee_id);
CREATE INDEX jhist_department_ix ON demo_hr.job_history (department_id);




-- demo_hr.employees definition
CREATE TABLE demo_hr.employees 
   (employee_id INTEGER, 
	first_name VARCHAR(20), 
	last_name VARCHAR(25) CONSTRAINT emp_last_name_nn NOT NULL, 
	email VARCHAR(25) CONSTRAINT emp_email_nn NOT NULL, 
	phone_number VARCHAR(20), 
	hire_date DATE CONSTRAINT emp_hire_date_nn NOT NULL, 
	job_id VARCHAR(10) CONSTRAINT emp_job_nn NOT NULL, 
	salary INTEGER, 
	commission_pct NUMERIC(2,2), 
	manager_id INTEGER, 
	department_id INTEGER, 
	some_date_fmt1 VARCHAR(50), 
	some_date_fmt2 VARCHAR(50), 
	some_date_fmt3 VARCHAR(50), 
	some_date_fmt4 VARCHAR(50), 
	fake_ssn VARCHAR(11), 
	zip5 VARCHAR(5), 
	zip5or9 VARCHAR(10), 
	zip9 VARCHAR(10), 
	email_address VARCHAR(100), 
	 CONSTRAINT emp_salary_min CHECK (salary > 0), 
	 CONSTRAINT emp_email_uk UNIQUE (email), 
	 CONSTRAINT emp_emp_id_pk PRIMARY KEY (employee_id), 
	 CONSTRAINT emp_dept_fk FOREIGN KEY (department_id) REFERENCES demo_hr.departments (department_id), 
	 CONSTRAINT emp_job_fk FOREIGN KEY (job_id) REFERENCES demo_hr.jobs (job_id), 
	 CONSTRAINT emp_manager_fk FOREIGN KEY (manager_id) REFERENCES demo_hr.employees (employee_id)
   ) ;

CREATE INDEX emp_department_ix ON demo_hr.employees (department_id);
CREATE INDEX emp_job_ix ON demo_hr.employees (job_id);
CREATE INDEX emp_manager_ix ON demo_hr.employees (manager_id);
CREATE INDEX emp_name_ix ON demo_hr.employees (last_name, first_name);






