-- Script Pulls CSV file for benefitsfocus demographics
--- Updated By: mrmd      Update Date: 08/24/17   Comment: Added r.no_pays to script to group School Health 10 month
---                                                           Employees into Division -> 'HCD-SCH'
--              mrmd      Update Date: 04/06/18   Comment: Modified this version to include adj_service_date
--              mrmd      Update Date: 04/06/18   Comment: Change is similar to 8/24 change to classify some school health employees correctly.
--				mrmd		 Update Date: 03/07/2019 Comment: Modified term_reason and retired_indicator
--				mrmd		 Update Date: 4/2/2019	 Comment: Update location mapping to keep in sync with Location changes made for Engagedly.
--				mrmd		 Update Date: 4/22/2019	 Comment: Update job classes based on Julie's spreadsheet that contained categories
SET NOCOUNT ON

SELECT 
    QUOTENAME('##############','"') as 'Client ID', 
    getdate() as 'Creation Date', 
    QUOTENAME(FORMAT(getdate(),'hhmm'),'"') as time,
                QUOTENAME('FF','"') as file_type,
                (SELECT QUOTENAME(COUNT(DISTINCT(e.empl_no)),'"') FROM 
    employee e 
    INNER JOIN payrate r on  e.empl_no = r.empl_no  
    INNER JOIN clstable c on r.classify = c.class_cd
    INNER JOIN calendar cal on   r.cal_type = cal.cal_type
    INNER JOIN person p on e.empl_no = p.empl_no 
    INNER JOIN posnhist s on r.empl_no = s.empl_no and r.classify = s.classify 
    LEFT JOIN tertable m on p.term_code=m.code
    LEFT JOIN  emplinfo f on e.empl_no = f.empl_no
    LEFT JOIN employee_type t on p.empl_type = t.code 
    LEFT JOIN empuser u on  e.empl_no = u.empl_no and u.page_no=4
    WHERE
    -------------------------------------------------------------------------
    -- logic in the where clause says only full time employees with benefits
    -- and excludes employees with a term date 2 weeks prior to current date
    -------------------------------------------------------------------------
    (p.term_date is null or p.term_date>= getdate()- 14 ) 
AND (s.enddate is null or s.enddate=p.term_date)
AND  r.fte>='0.8' 
    ) as record_count,
    QUOTENAME('Y','"') as 'safeguard_usage',
    QUOTENAME('Y','"') as 'auto_appr_bnfts',
    QUOTENAME('2','"') as 'login_method',
    QUOTENAME('','"') as 'password_method',
    QUOTENAME('V8','"') as 'version'

SELECT DISTINCT
    QUOTENAME(left (e.ssn,3)+ SUBSTRING(e.ssn,5,2)+RIGHT(e.ssn,4),'"') as ssn, 
--    QUOTENAME('111111111','"') as ssn,
    QUOTENAME((ltrim(rtrim(e.l_name))),'"') as l_name, 
    QUOTENAME((ltrim(rtrim(e.f_name))),'"') as f_name, 
    ISNULL (QUOTENAME((ltrim(rtrim(e.m_name))),'"'),'""') as m_name, 
    name_suffix = CASE QUOTENAME(e.name_suffix,'"') WHEN 'JR' then 'Jr.' WHEN  'SR' then 'Sr.' Else '""' END, 
    QUOTENAME((ltrim(rtrim(REPLACE(e.addr1, ',', '')))),'"') as street1,
    QUOTENAME((ltrim(rtrim(ISNULL(e.addr2, '')))),'"') as street2,
    QUOTENAME((ltrim(rtrim(REPLACE(e.city,',' , '')))),'"') as city, 
    QUOTENAME((ltrim(rtrim(REPLACE (e.state_id, ',' , '')))),'"') as state,
    QUOTENAME(SUBSTRING(e.zip, 1,5),'"') as zip,
    QUOTENAME('USA','"') as Country,
    QUOTENAME('','"') as name_add_chg_dt,
    QUOTENAME(FORMAT(e.birthdate, 'yyyyMMdd'),'"') AS birthdate,
    QUOTENAME(p.sex,'"') as gender,
    QUOTENAME('','"') as 'marital_status'		         ,
    QUOTENAME('','"') as 'ethnicity'	    		     ,
    QUOTENAME('','"') as 'home_phone'                    ,
    QUOTENAME('','"') as 'cell_phone'                    ,
    QUOTENAME('','"') as 'personal_email'                ,
    QUOTENAME('','"') as 'emergency_contact'             ,
    QUOTENAME('','"') as 'emergency_contact_relationship',
    QUOTENAME('','"') as 'emergency_contact_phone'       ,
    QUOTENAME('','"') as 'emergency_contact_alt_phone'   ,
    QUOTENAME('','"') as 'emergency_contact_add1'        ,
    QUOTENAME('','"') as 'emergency_contact_add2'        ,
    QUOTENAME('','"') as 'emergency_contact_city'        ,
    QUOTENAME('','"') as 'emergency_contact_state'       ,
    QUOTENAME('','"') as 'emergency_contact_zip'         ,
    QUOTENAME('','"') as 'emergency_contact_country'     ,
    QUOTENAME(FORMAT(e.hire_date, 'yyyyMMdd'),'"') AS hire_date    ,
    QUOTENAME(ISNULL(FORMAT(cast(u.ftext1 as date), 'yyyyMMdd'),''),'"') 'adj_service_date', -- Used for Benefit Startdate
    QUOTENAME('','"') as 'other_date',
    QUOTENAME(ISNULL(FORMAT(p.term_date,'yyyyMMdd'),''),'"') as term_date,
    ---------------------------------------------
    -- case statement maps term_code with reason
    ---------------------------------------------
    term_reason = CASE term_code
				WHEN '2'   THEN QUOTENAME('I','"')
				WHEN '5'   THEN QUOTENAME('I','"')
				WHEN '15'  THEN QUOTENAME('I','"')
				WHEN '1'   THEN QUOTENAME('V','"')
				WHEN '4'   THEN QUOTENAME('V','"')
				WHEN '14'  THEN QUOTENAME('V','"')
                WHEN 'DNS' THEN QUOTENAME('V','"')
				WHEN '3'   THEN QUOTENAME('D','"')
				ELSE '""' 
				END,
    retired_indicator = CASE p.status
                WHEN 'RET' THEN QUOTENAME('Y','"')
                ELSE QUOTENAME('N','"')
                END,
    QUOTENAME(r.annl_sal,'"') as annualsalary,
    QUOTENAME('ANNUAL','"') as 'earning_unit_of_measure',
    QUOTENAME('BIWEEKLY','"') as 'pay_frequency',
    QUOTENAME('','"') as earn_amount_eff_date,
    QUOTENAME('','"') as salary_override_amount,
    QUOTENAME('','"') as salary_override_unit,
    QUOTENAME('','"') as earning_ammount_eff_date_sovr,
    QUOTENAME('','"') as eeoc,
    QUOTENAME('','"') as occupation,
    QUOTENAME(e.empl_no,'"') as member_id,
    QUOTENAME('','"') as work_phone,
    QUOTENAME('','"') as work_cell_phone,
    QUOTENAME('','"') as work_pager,
    QUOTENAME('','"') as work_email,
    QUOTENAME('','"') as scheduled_work_hours,
    QUOTENAME('','"') as custom_cat_eff_date,
    QUOTENAME('Status','"') as custom_cat_type1,
    CASE
		WHEN  stb.code = 'RET' THEN 	QUOTENAME('Retiree','"')
		WHEN  p.part_time = 'F' THEN QUOTENAME('Full-Time','"')
		WHEN  p.part_time IS NULL THEN QUOTENAME('Full-Time','"')
	END as custom_cat_value1,
    QUOTENAME('Division','"') as custom_cat_type2,	
	    CASE 
        ------------------------------------------
        -- MAPS location to code to location name
        ------------------------------------------
        WHEN (e.home_orgn =110 or e.home_orgn=619 or e.home_orgn =621 or e.home_orgn =622 or e.home_orgn=624
		or home_orgn between 628 and 640) THEN QUOTENAME('EJH','"')
        WHEN ((e.home_orgn between 870 and 874) or e. home_orgn = 876
		or (home_orgn between 878 and 890) or e.home_orgn=892) THEN QUOTENAME('FQHC','"')
        WHEN (home_orgn=135 or home_orgn=601 or (home_orgn between 604 and 606)
		or e.home_orgn=608 or e.home_orgn=612 or e.home_orgn=617 or e.home_orgn=641 or e.home_orgn=643
		or e.home_orgn=701 or e.home_orgn=704 or e.home_orgn=707 or e.home_orgn=730 or e.home_orgn=736
		or e.home_orgn=806 or e.home_orgn=809 or e.home_orgn=818 or (e.home_orgn between 821 and 822) 
		or e.home_orgn =831 or e.home_orgn=833 or (e.home_orgn between 839 and 840) or e.home_orgn=858) THEN QUOTENAME('LMC','"')
        WHEN home_orgn=133 THEN QUOTENAME('HCD-AERO','"')
        WHEN home_orgn=145 THEN QUOTENAME('HCD-RX','"')
        WHEN home_orgn=153 and r.no_pays=22.0 THEN QUOTENAME('HCD-SCH','"')
        ELSE QUOTENAME('HCD','"')
    END as custom_cat_value2,
    QUOTENAME('Class','"') as custom_cat_type3,
    CASE
        ------------------------------------------
        -- MAPS Job Classification
        ------------------------------------------
        WHEN lower(c.title) in ('chief executive officer','vp cmo','vp field operations','vp of strategy','vp cfo','vp hr and communications','vp general counsel','chief information officer','chief comp priv offcr','dir clinical services','dir pat satis hosp comm','dental director','dir cred provider serv','dir food nutrition ser','dir fqhc business devel','dir fqhc pediatric svcs','dir fqhc womens health','dir healey support svcs','dir hlth info mgmt','dir it software support','dir pat satis hosp comm','dir revenue cycle mgmt','dir trauma clin aeromed','director accounting','director aviation operat','director communications','director corp quality','director finance','director human resources','director of eligibility','director of facilities','director of nursing','director of um','director of patient access','director of pharmacy','director rehabilitation','director school health','director of social services') THEN QUOTENAME('EXEC','"')
        WHEN lower(c.title) like 'physician' or lower(c.title) = 'pediatrician' or lower(c.title) ='psychiatrist' or lower(c.title) ='medical director fqhc' or lower(c.title)='dir behavioral health' or lower(c.title) ='dentist' THEN QUOTENAME('PHYS','"') 
        ELSE QUOTENAME('GENERAL','"') 
    END as custom_cat_value3,
    QUOTENAME('Grandfathered Employees','"') as custom_cat_type4,
    QUOTENAME('No','"') as custom_cat_value4,
    QUOTENAME('Wellness','"') as custom_cat_type5,
    QUOTENAME('Yes','"') as custom_cat_value5,
    QUOTENAME('','"') as custom_cat_type6,
    QUOTENAME('','"') as custom_cat_value6,
    QUOTENAME('','"') as custom_cat_type7,
    QUOTENAME('','"') as custom_cat_value7,
    QUOTENAME('','"') as custom_cat_type8,
    QUOTENAME('','"') as custom_cat_value8,
    QUOTENAME('','"') as custom_cat_type9,
    QUOTENAME('','"') as custom_cat_value9,
    QUOTENAME('','"') as custom_cat_type10,
    QUOTENAME('','"') as custom_cat_value10,
    QUOTENAME('','"') as custom_cat_type11,
    QUOTENAME('','"') as custom_cat_value11,
    QUOTENAME('','"') as custom_cat_type12,
    QUOTENAME('','"') as custom_cat_value12,
    QUOTENAME('','"') as custom_cat_type13,
    QUOTENAME('','"') as custom_cat_value13,
    QUOTENAME('','"') as custom_cat_type14,
    QUOTENAME('','"') as custom_cat_value14,
    QUOTENAME('','"') as custom_cat_type15,
    QUOTENAME('','"') as custom_cat_value15
FROM 
    employee e 
    INNER JOIN payrate r on  e.empl_no = r.empl_no  
    INNER JOIN clstable c on r.classify = c.class_cd
    INNER JOIN calendar cal on   r.cal_type = cal.cal_type
    INNER JOIN person p on e.empl_no = p.empl_no 
    INNER JOIN posnhist s on r.empl_no = s.empl_no and r.classify = s.classify
    LEFT JOIN tertable m on p.term_code=m.code
    LEFT JOIN  emplinfo f on e.empl_no = f.empl_no
    LEFT JOIN employee_type t on p.empl_type = t.code 
    LEFT JOIN empuser u on  e.empl_no = u.empl_no and u.page_no=4
	LEFT JOIN statustb stb on stb.code = p.status
WHERE
    -------------------------------------------------------------------------
    -- logic in the where clause says only full time employees with benefits
    -- and excludes employees with a term date 2 weeks prior to current date
    -------------------------------------------------------------------------
    (p.term_date is null or p.term_date>= getdate()- 14 ) 
AND (s.enddate is null or s.enddate=p.term_date)
AND  r.fte>='0.8'