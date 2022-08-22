****KL Final Version Views Script
**** Created 8/3/2018

# Custom Views Created for knowledgelake



* Note - Views being created in schema[dbo] to support permission chains.

### Payroll View
### Created mrmd
CREATE VIEW dbo.v_kl_payroll_check AS
SELECT        rtrim(checkhi2.check_no) CheckNum, sum(checkhi2.amt) as CheckAmt, checkhis.iss_date as CheckDate, rtrim(employee.empl_no) EmployeeID, rtrim(employee.f_name) EmployeeFirstName, rtrim(employee.l_name) EmployeeLastName,   
			  checkhis.pay_run, checkhis.trans_date as checkrundate
FROM          employee INNER JOIN
              checkhi2 ON employee.empl_no = checkhi2.empl_no
			  INNER JOIN checkhis ON checkhi2.empl_no=checkhis.empl_no and checkhi2.check_no = checkhis.check_no
where code = '001'
group by employee.empl_no, employee.f_name, employee.l_name, checkhi2.check_no, checkhis.iss_date, checkhis.pay_run, checkhis.trans_date



#### W2 View: v_kl_w2_info
## Created mrmd
## Sharon suggested we only show the a single year

## Only 2017

CREATE VIEW dbo.v_kl_w2_info AS
SELECT  
	   rtrim([empl_no]) EmployeeID	
      ,rtrim([fname]) EmployeeFirstName
      ,rtrim([lname]) EmployeeLastName
      ,max([taxyr]) as taxyr     
FROM [testmydb51].[dbo].[w2employee]
group by fname, lname, empl_no


#### AP CHECKS VIEW:
## 10/17/2018 Added rtrim to remove blank spaces
## 8/6/2018 Added group by to Stuff function so that field wouldn't contain dupes
Created 8/2/2018 verified using - and check_no='286041' and transact.vend_no = '909415'
CREATE VIEW dbo.v_kl_ap_checks AS
SELECT distinct transact.check_no CheckNum, Sum(transact.trans_amt)as CheckAmt, transact.ck_date CheckDate, transact.vend_no VendorNumber, vendor.ven_name VendorName, transact.yr FY,
	stuff ((select ',' + rtrim(t1.invoice) 
	FROM  vendor v1 INNER JOIN transact t1 ON v1.vend_no = t1.vend_no
	WHERE
	t1.check_no >'0' 
	and t1.check_no = check_no 
	and t1.enc_no = enc_no
	and t1.vend_no = transact.vend_no
	and t1.check_no = transact.check_no
	and ck_date > '2015-12-31 00:00:00'
	group by t1.invoice
		FOR XML PATH('')), 1, LEN(','), '') as InvoiceNum
	,stuff ((select ',' + rtrim(t1.enc_no) 
	FROM  vendor v1 INNER JOIN transact t1 ON v1.vend_no = t1.vend_no
	WHERE 
	t1.check_no >'0' 
	and t1.check_no = check_no 
	and t1.enc_no = enc_no
	and t1.vend_no = transact.vend_no
	and t1.check_no = transact.check_no
	and ck_date > '2015-12-31 00:00:00'
	and t1.ck_date = ck_date
	group by t1.enc_no
		FOR XML PATH('')), 1, LEN(','), '') as PONum	
FROM   vendor INNER JOIN transact ON vendor.vend_no = transact.vend_no
WHERE check_no >'0' and ck_date > '2015-12-31 00:00:00'
GROUP by check_no, ck_date,transact.vend_no, ven_name, yr



#### Purchase Orders View
## 10/25/2020 Removed stuff function so script pulls all POs including those with no invoice associated
## -> 10/25 cont: Alost only pulls FY >=19
## 10/17/2018 Added rtrim to remove blank spaces
## 8/6/2018 Added group by to Stuff function so that field wouldn't contain dupes
## 8/3/2018 grouping with check date removed - verified with this PONum --> enc_no = '170###'

CREATE VIEW dbo.v_kl_purchase_orders AS
SELECT DISTINCT
rtrim(transact.enc_no) as PONum, transact.invoice, rtrim(transact.vend_no) VendorNumber, 
vendor.ven_name VendorName, 
transact.yr
FROM   vendor INNER JOIN transact ON vendor.vend_no = transact.vend_no
WHERE vendor.vend_no=transact.vend_no and transact.yr >='19'



#### Invoices View
## Updated 9/14/18 had to modify group by because view was still returning multiple rows per invoice
## Version has correct column orders 8/1/2018
## Version added group by in stuff function to get rid of dupes 8/6/2018
#### Created 7/23 - This will provide invoices associated with specific PO's


CREATE VIEW dbo.v_kl_invoices AS
SELECT distinct transact.invoice InvoiceNumber, vendor.vend_no VendorNumber,
	stuff ((select  ',' + rtrim(t1.check_no)
	FROM  vendor v1 INNER JOIN transact t1 ON v1.vend_no = t1.vend_no
	WHERE v1.vend_no=t1.vend_no 
	and t1.check_no >'0' 
	and t1.check_no = check_no 
	and t1.vend_no = transact.vend_no 
	and transact.enc_no = enc_no 
	and t1.invoice = transact.invoice
	and ck_date > '2015-12-31 00:00:00' and t1.ck_date = ck_date
    GROUP By t1.check_no
		FOR XML PATH('')), 1, LEN(','), '') as CheckNum,
vendor.ven_name VendorName, Sum(transact.trans_amt)as CheckAmt, transact.yr FY,
transact.enc_no as PONum
FROM   vendor INNER JOIN transact ON vendor.vend_no = transact.vend_no
WHERE vendor.vend_no=transact.vend_no and check_no >'0' and ck_date > '2015-12-31 00:00:00' --and invoice='00001####'
GROUP by transact.invoice, transact.vend_no, ven_name, vendor.vend_no, yr, enc_no


#### HR  Employee View:
#### modified 10/31/2018 to add logic to only return one record for employees who have duplicate records. Returns most recent hire_date ##                       entry
#### modified 10/26/2018 to add FullName column to add 
#### modified 10/5/2018 to populate term_date and job title
#### modified 7/18/2018 add Driver License
## How is former name broken out in DB
CREATE VIEW dbo.v_kl_HR_employee_detail AS
SELECT * FROM
(
SELECT Distinct  rtrim(employee.empl_no) EmployeeID, rtrim(employee.f_name) EmployeeFirstName, rtrim(employee.l_name) EmployeeLastName, rtrim(employee.prev_lname) FormerName,
CONCAT (rtrim(employee.f_name ),' ',rtrim(employee.l_name),' ', rtrim(employee.empl_no)) FullName, rtrim(employee.ssn) EmployeeSSN, 
employee.hire_date HireDate, p.term_date, CONCAT (rtrim(employee.home_orgn), '-',rtrim(d.desc_x)) as department, c.title
, ROW_NUMBER() over (PARTITION BY ssn, CONCAT (rtrim(employee.f_name ),' ',rtrim(employee.l_name)) ORDER BY employee.hire_date DESC) rn
FROM employee
INNER JOIN person p on employee.empl_no = p.empl_no
LEFT JOIN payrate r on  employee.empl_no = r.empl_no  
LEFT JOIN clstable c on r.classify = c.class_cd
LEFT JOIN dept d ON d.code = employee.home_orgn
--WHERE employee.l_name ='ADE'
) x
WHERE rn = 1 
go



##### HR EMPLOYEE DETAIL from 10/26/2018
CREATE VIEW dbo.v_kl_HR_employee_detail AS
SELECT Distinct  rtrim(employee.empl_no) EmployeeID, rtrim(employee.f_name) EmployeeFirstName, rtrim(employee.l_name) EmployeeLastName, rtrim(employee.prev_lname) FormerName,
CONCAT (rtrim(employee.f_name),rtrim(employee.l_name)) FullName, rtrim(employee.ssn) EmployeeSSN, 
employee.hire_date HireDate, p.term_date, CONCAT (rtrim(employee.home_orgn), '-',rtrim(d.desc_x)) as department, c.title
FROM employee
INNER JOIN person p on employee.empl_no = p.empl_no
LEFT JOIN payrate r on  employee.empl_no = r.empl_no  
LEFT JOIN clstable c on r.classify = c.class_cd
LEFT JOIN dept d ON d.code = employee.home_orgn
go



#### v_kl_PO_requestor_detail 12/13/2019
CREATE VIEW dbo.v_kl_PO_requestor_detail
SELECT distinct x.vend_no, x.po_no, x.location as dept_number, x.po_date
,su.email, su.uid as requestor, su.lname, su.fname
, x.key_orgn
from (
SELECT distinct p.vend_no, p.po_no, p.location, p.po_date, p.requestor, t.key_orgn 
FROM [HCD-VMS-FPDB].mydb51.dbo.purchase p
LEFT JOIN [HCD-VMS-MYDB].mydb51.dbo.transact t ON p.po_no = t.enc_no and p.yr=t.yr
WHERE
p.po_date >= '2019-10-01 00:00:00'	and t.trans_date >= p.po_date
--and sectb_roles.role_descript like('%RECEIVE%')
) x
LEFT JOIN [HCD-VMS-FPDB].mydb51.dbo.sectb_user su ON x.requestor = su.uid
LEFT JOIN [HCD-VMS-FPDB].mydb51.dbo.sectb_roleusers sr on su.uid = sr.spiuser
LEFT JOIN [HCD-VMS-FPDB].mydb51.dbo.sectb_roles sro on sr.role_id = sro.role_id
--LEFT JOIN person p on e.empl_no = p.empl_no
--WHERE p.term_date is null or p.term_date >= '2015-01-01 00:00:00'
and sro.role_descript like('%RECEIVERS%')
order by x.location


######## Version before 10/25/2018

CREATE VIEW dbo.v_kl_HR_employee_detail AS
SELECT Distinct  rtrim(employee.empl_no) EmployeeID, rtrim(employee.f_name) EmployeeFirstName, rtrim(employee.l_name) EmployeeLastName, rtrim(employee.ssn) EmployeeSSN, 
employee.hire_date HireDate
FROM employee

#####  Per project team we changed HR_DL view to employee_license to pull all licenses
Change HR Driver License view:

CREATE VIEW dbo.v_kl_HR_employee_license AS
SELECT Distinct rtrim(ec.number) as EmployeeLicense, rtrim(employee.empl_no) EmployeeID, rtrim(employee.f_name) EmployeeFirstName, rtrim(employee.l_name) EmployeeLastName, ec.iss_date, ec.exp_date
FROM employee
LEFT JOIN emp_certificate ec ON employee.empl_no = ec.empl_no where ec.number IS NOT NULL