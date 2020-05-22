# OCI_to_Azure_Automation
Terraform and Ansible Scripts to automate the provisioning and setup of OCI and Azure Virtual Private Circuit.

## Prerequirements
Clone the Github Repo, then go to https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html and download the Instant Client .zip. I personally used instantclient-basic-linux.x64-19.6.0.0.0dbru.zip. After this step is done rename the file to instantclient.zip and place it inside the cloned directory.

![alt text](https://github.com/cj667113/OCI_to_Azure_Automation/blob/master/oci_to_azure_architecture_diagram/oci_to_azure_architecture_diagram.png)

### Generate an OCI API API Signing Key for your OCI User and Upload the Public Key:

	https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm

### Generate SSH Key Pairs

	https://docs.cloud.oracle.com/en-us/iaas/Content/GSG/Tasks/creatingkeys.htm
	
## Requirements

### Run the configure.py script. This will output a json file to be used as variables in Terraform.

For Region and Location variables:

	OCI = "us-ashburn-1"
	
	Azure = "East US"

For Address Space variables:
	
	Please use two different /16 subnet, however ommit the /16.
  
	Example 10.255.0.0 for OCI and 10.124.0.0 for Azure.
	
### Execute the Terraform Script

terraform apply --auto-approve
