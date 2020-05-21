import cx_Oracle
import json
f=open("../config.json")
cred=json.load(f)
f.close()
db_service=(cred['last_name'][0].lower())+'adw01_low'
connection = cx_Oracle.connect('Admin',cred['adb_password'],db_service)
cursor = connection.cursor()
try:
	cursor.execute("select * from Employees")
	data = cursor.fetchall()
	for element in data:
		print(element)
	connection.close()
except:
	raise
