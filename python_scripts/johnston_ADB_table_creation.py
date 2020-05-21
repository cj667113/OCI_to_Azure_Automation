import cx_Oracle
import json
f=open("../config.json")
cred=json.load(f)
f.close()
db_service=(cred['last_name'][0].lower())+'adw01_low'
connection = cx_Oracle.connect('Admin',cred['adb_password'],db_service)
cursor = connection.cursor()
try:
	cursor.execute("create table Employees (EMPLOYEEID VARCHAR2(255),FIRSTNAME VARCHAR2(255),LASTNAME VARCHAR2(255))")
	cursor.execute("insert into Employees (EMPLOYEEID,FIRSTNAME,LASTNAME) values('12345','Elissa','French')")
	cursor.execute("insert into Employees (EMPLOYEEID,FIRSTNAME,LASTNAME) values('12346','Jacque', 'Brown')")
	cursor.execute("insert into Employees (EMPLOYEEID,FIRSTNAME,LASTNAME) values('12347','Cairo','Allman')")
	cursor.execute("insert into Employees (EMPLOYEEID,FIRSTNAME,LASTNAME) values('12348','Fabio','Hulme')")
	cursor.execute("insert into Employees (EMPLOYEEID,FIRSTNAME,LASTNAME) values('12349','Alesha','Chambers')")
	connection.commit()
	connection.close()
except:
	print("Table Exists")
