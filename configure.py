import json
last_name = raw_input("Please Enter your Last Name: ")
tenancy_ocid = raw_input("Please Enter the Oracle Cloud Tenancy OCID: ")
compartment_ocid = raw_input("Please Enter your OCI Compartment OCID: ")
user_ocid = raw_input("Please Enter the OCI User's OCID: ")
fingerprint=raw_input("Please Enter the OCI User's API Fingerprint: ")
private_key_path=raw_input("Please Enter the Path to the Private Key Used to Generate the OCI User's Fingerprint (.pem): ")
region=raw_input("Please Enter the OCI Region you wish to use: ")
azure_subscription_id=raw_input("Please Enter the Azure Subscription ID: ")
azure_tenant_id=raw_input("Please Enter the Azure Tenant ID: ")
azure_location=raw_input("Please Enter the Azure Location: ")
oci_address_space=raw_input("Please Enter a non-overlapping Network Address for OCI VCN (Not 192.168.0.0/16 address space): ")
azure_address_space=raw_input("Please Enter a non-overlapping Network Address for Azure VN (Not 192.168.0.0/16 address space): ")
private_ssh_key=raw_input("Please Enter the Path to the Private SSH Key to provision instances: ")
public_ssh_key=raw_input("Please Enter the Path to the Public SSH Key to provision instance: ")
public_ssh_key_path=public_ssh_key
private_ssh_key_path=private_ssh_key
username=raw_input("Please Enter a username to use on the instances: ")
adb_password=raw_input("Please Enter a Password for the Autonomous Database: ")
with open(private_ssh_key, 'r') as content_file:
	private_ssh_key_string = content_file.read()
with open(public_ssh_key, 'r') as content_file:
	public_ssh_key_string = content_file.read()
configuration = {'last_name':last_name,'tenancy_ocid':tenancy_ocid, 'compartment_ocid':compartment_ocid, 'user_ocid':user_ocid, 'fingerprint':fingerprint, 'private_key_path':private_key_path,'region':region,'azure_subcription_id':azure_subscription_id, 'azure_tenant_id':azure_tenant_id, 'azure_location': azure_location, 'oci_address_space':oci_address_space, 'azure_address_space':azure_address_space, 'private_ssh_key':private_ssh_key_string, 'public_ssh_key':public_ssh_key_string, 'username':username, 'adb_password':adb_password, 'public_ssh_key_path': public_ssh_key_path, 'private_ssh_key_path':private_ssh_key_path}
data=json.dumps(configuration,indent=4)
with open("config.json","w") as file:
	file.write(data)
