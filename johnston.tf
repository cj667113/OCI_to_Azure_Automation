terraform {
	required_providers {
		azurerm = "1.44.0"
		local = "1.4.0"
		oci = "3.70.0"
	}
}
locals  {
	json_data=jsondecode(file("config.json"))
}
provider "oci" {
	tenancy_ocid=local.json_data.tenancy_ocid
	user_ocid=local.json_data.user_ocid
	fingerprint = local.json_data.fingerprint
	private_key_path =local.json_data.private_key_path
	region =local.json_data.region
	private_key_password=local.json_data.private_key_password
}
resource "oci_core_vcn" "VCN_1" {
	cidr_block = "${local.json_data.oci_address_space}/16"
	dns_label = "${substr(local.json_data.last_name,0,1)}vcn1"
	compartment_id = local.json_data.compartment_ocid
	display_name="${(local.json_data.last_name)}_VCN_1"
}

data "oci_core_vcn" "VCN_1" {
	vcn_id = oci_core_vcn.VCN_1.id
}

resource "oci_core_subnet" "VCN_1_Subnet_1" {
	cidr_block = "${element(split(".",local.json_data.oci_address_space),0)}.${element(split(".",local.json_data.oci_address_space),1)}.255.0/24"
	compartment_id=local.json_data.compartment_ocid
	vcn_id = data.oci_core_vcn.VCN_1.id
	display_name="${local.json_data.last_name}_VCN_1_Subnet_1"
	security_list_ids = [oci_core_security_list.VCN_1_Security_List_1.id]
	dns_label="${substr(local.json_data.last_name,0,1)}vcn1S1"
}
resource "oci_core_subnet" "VCN_1_Subnet_2" {
        cidr_block = "${element(split(".",local.json_data.oci_address_space),0)}.${element(split(".",local.json_data.oci_address_space),1)}.254.0/30"
        compartment_id=local.json_data.compartment_ocid
        vcn_id = data.oci_core_vcn.VCN_1.id
        display_name="${local.json_data.last_name}_VCN_1_Subnet_2"
        security_list_ids = [oci_core_security_list.VCN_1_Security_List_1.id]
        dns_label="${substr(local.json_data.last_name,0,1)}vcn1S2"
}
resource "oci_core_drg" "DRG_1_1" {
	compartment_id=local.json_data.compartment_ocid
	display_name="${local.json_data.last_name}_DRG_1_1"
}

resource "oci_core_network_security_group" "SG_1" {
	compartment_id=local.json_data.compartment_ocid
	vcn_id=oci_core_vcn.VCN_1.id
	display_name="${local.json_data.last_name}_SG_1"
}

resource "oci_core_network_security_group_security_rule" "SG_1_R1" {
	network_security_group_id = oci_core_network_security_group.SG_1.id
	direction="INGRESS"
	protocol="all"
	destination = "0.0.0.0/0"
	destination_type = "CIDR_BLOCK"
	source="10.0.0.0/8"
	source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "SG_1_R2" {
        network_security_group_id = oci_core_network_security_group.SG_1.id
        direction="EGRESS"
        protocol="all"
        destination = "0.0.0.0/0"
        destination_type = "CIDR_BLOCK"
        source="0.0.0.0/0"
        source_type = "CIDR_BLOCK"
}

resource "oci_core_drg_attachment" "DRG_1_Attachment_VCN_1"{
	drg_id=oci_core_drg.DRG_1_1.id
	vcn_id=oci_core_vcn.VCN_1.id
	display_name="${local.json_data.last_name}_DRG_1_Attachment_Johnston_VCN_1"
}

data "oci_core_services" "Services" {
}

resource "oci_core_service_gateway" "SGW_1" {
	compartment_id=local.json_data.compartment_ocid
	services {
		service_id=data.oci_core_services.Services.services.1.id
	}
	display_name="${local.json_data.last_name}_SGW_1"
	vcn_id = data.oci_core_vcn.VCN_1.id
	route_table_id = oci_core_route_table.VCN_1_Route_Table_2.id
}
resource "oci_core_route_table" "VCN_1_Route_Table_1" {
	compartment_id=local.json_data.compartment_ocid
        vcn_id =oci_core_vcn.VCN_1.id
        display_name = "${local.json_data.last_name}_VCN_1_Route_Table_1"
        route_rules {
        network_entity_id=oci_core_internet_gateway.VCN_1_IGW.id
        destination_type="CIDR_BLOCK"
        destination="0.0.0.0/0"
        }
        route_rules {
        network_entity_id=oci_core_drg.DRG_1_1.id
        destination_type="CIDR_BLOCK"
        destination="${local.json_data.azure_address_space}/16"
        }
}
resource "oci_core_route_table" "VCN_1_Route_Table_2" {
	compartment_id=local.json_data.compartment_ocid
        vcn_id =oci_core_vcn.VCN_1.id
        display_name = "${local.json_data.last_name}_VCN_1_Route_Table_2"
	route_rules {
        network_entity_id=oci_core_drg.DRG_1_1.id
        destination_type="CIDR_BLOCK"
        destination="${local.json_data.azure_address_space}/16"
        }
}

resource "oci_core_route_table_attachment" "Route_Table_Attachment_1" {
	subnet_id = oci_core_subnet.VCN_1_Subnet_1.id
	route_table_id = oci_core_route_table.VCN_1_Route_Table_1.id
}

resource "oci_core_route_table_attachment" "Route_Table_Attachment_2" {
        subnet_id = oci_core_subnet.VCN_1_Subnet_2.id
        route_table_id = oci_core_route_table.VCN_1_Route_Table_1.id
}

resource "oci_core_internet_gateway" "VCN_1_IGW" {
	compartment_id=local.json_data.compartment_ocid
	vcn_id =oci_core_vcn.VCN_1.id
	display_name="${local.json_data.last_name}_VCN_1_IGW"
}
resource "oci_core_security_list" "VCN_1_Security_List_1"{
	compartment_id=local.json_data.compartment_ocid
	vcn_id=oci_core_vcn.VCN_1.id
	display_name="${local.json_data.last_name}_VCN_1_Security_List_1"
	egress_security_rules {
	destination = "0.0.0.0/0"
		protocol = "all"
	}
	ingress_security_rules {
		protocol = "6"
		source ="0.0.0.0/0"
		tcp_options {
			max = "22"
			min = "22"
		}
	}
        ingress_security_rules {
                protocol = "6"
                source ="0.0.0.0/0"
                tcp_options {
                	max = "1433"
                	min = "1433"
                }
        }
        ingress_security_rules {
                protocol = "1"
                source ="0.0.0.0/0"
                icmp_options {
                        type="1"
                }
	}
	ingress_security_rules {
                protocol = "1"
                source ="0.0.0.0/0"
                icmp_options {
                        type="8"
                }
	}
        ingress_security_rules {
               protocol = "1"
                source ="0.0.0.0/0"
                icmp_options {
                        type="30"
                }
	}        
}

provider "azurerm" {
	subscription_id = local.json_data.azure_subcription_id
	tenant_id = local.json_data.azure_tenant_id
}
resource "azurerm_resource_group" "OCI_Azure" {
	name = "${local.json_data.last_name}_OCI_Azure"
	location = local.json_data.azure_location
}
resource "azurerm_virtual_network" "VN_1" {
	name="${local.json_data.last_name}_VN_1"
	resource_group_name = azurerm_resource_group.OCI_Azure.name
	location = azurerm_resource_group.OCI_Azure.location
	address_space = ["${local.json_data.azure_address_space}/16"]
}
resource "azurerm_subnet" "VN_1_Subnet_1" {
	name = "${local.json_data.last_name}_VN_1_Subnet_1"
	resource_group_name = azurerm_resource_group.OCI_Azure.name
	virtual_network_name = azurerm_virtual_network.VN_1.name
	address_prefix = "${element(split(".",local.json_data.azure_address_space),0)}.${element(split(".",local.json_data.azure_address_space),1)}.255.0/24"
}

resource "azurerm_subnet" "GatewaySubnet" {
        name = "GatewaySubnet"
        resource_group_name = azurerm_resource_group.OCI_Azure.name
        virtual_network_name = azurerm_virtual_network.VN_1.name
        address_prefix = "${element(split(".",local.json_data.azure_address_space),0)}.${element(split(".",local.json_data.azure_address_space),1)}.0.0/24"
}
resource "azurerm_public_ip" "VN_1_Gateway_1_IP" {
	name = "${local.json_data.last_name}_VN_1_Gateway_1_IP"
	location = azurerm_resource_group.OCI_Azure.location
	resource_group_name = azurerm_resource_group.OCI_Azure.name
	allocation_method = "Dynamic"
}
resource "azurerm_virtual_network_gateway" "VN_1_Gateway" {
	name = "${local.json_data.last_name}_VN_1_Gateway"
	location = azurerm_resource_group.OCI_Azure.location
	resource_group_name = azurerm_resource_group.OCI_Azure.name
	type="ExpressRoute"
	active_active = false
	enable_bgp = true
	sku = "Standard"
	ip_configuration {
		name = "${local.json_data.last_name}_VN_1_Gateway_Config"
		public_ip_address_id = azurerm_public_ip.VN_1_Gateway_1_IP.id
		private_ip_address_allocation ="Dynamic"
		subnet_id = azurerm_subnet.GatewaySubnet.id
	}	
}
resource "azurerm_route_table" "VN_1_RouteTable_1" {
	name = "${local.json_data.last_name}_VN_1_RouteTable_1"
	location = azurerm_resource_group.OCI_Azure.location
	resource_group_name = azurerm_resource_group.OCI_Azure.name
	route {
		name = "${local.json_data.last_name}_VN_1_RouteTable_1_Route_1"
		address_prefix = "${local.json_data.oci_address_space}/16"
		next_hop_type="VirtualNetworkGateway"
	}
}
resource "azurerm_subnet_route_table_association" "VN_1_RouteTable_Association_1" {
	subnet_id = azurerm_subnet.VN_1_Subnet_1.id
	route_table_id = azurerm_route_table.VN_1_RouteTable_1.id
}

resource "azurerm_express_route_circuit" "VN_1_ER_1" {
	name="${local.json_data.last_name}_VN_1_ER_1"
	resource_group_name = azurerm_resource_group.OCI_Azure.name
	location = azurerm_resource_group.OCI_Azure.location
	service_provider_name = "Oracle Cloud FastConnect"
	peering_location = "Washington DC"
	bandwidth_in_mbps = 50
	sku {
		tier = "Standard"
		family="MeteredData"
	}
}

resource "azurerm_virtual_network_gateway_connection" "CX_1" {
	name = "${local.json_data.last_name}_CX_1"
	location = azurerm_resource_group.OCI_Azure.location
	resource_group_name = azurerm_resource_group.OCI_Azure.name
	type = "ExpressRoute"
	virtual_network_gateway_id = azurerm_virtual_network_gateway.VN_1_Gateway.id
	express_route_circuit_id = azurerm_express_route_circuit.VN_1_ER_1.id
	depends_on = [oci_core_virtual_circuit.VN_1_Fast_Connect]
}

resource "oci_core_virtual_circuit" "VN_1_Fast_Connect" {
	compartment_id=local.json_data.compartment_ocid
	type = "PRIVATE"
	bandwidth_shape_name = "1 Gbps"
	cross_connect_mappings {
		customer_bgp_peering_ip = "192.168.1.2/30"
	}
	cross_connect_mappings {
		customer_bgp_peering_ip = "192.168.0.2/30"
        }
	display_name="${local.json_data.last_name}_VN_1_Fast_Connect"
	gateway_id = oci_core_drg.DRG_1_1.id
	provider_service_id = "ocid1.providerservice.oc1.iad.aaaaaaaamdyta753fb6tshj3p2g5zezjwfoki5l46jcaaikxt3hszboiag4q"
	provider_service_key_name = azurerm_express_route_circuit.VN_1_ER_1.service_key
	depends_on = [azurerm_virtual_network_gateway.VN_1_Gateway]
}

data "oci_identity_availability_domains" "oad" {
	compartment_id=local.json_data.compartment_ocid
}

data "oci_core_shapes" "shapes" {
	compartment_id=local.json_data.compartment_ocid
	availability_domain = data.oci_identity_availability_domains.oad.availability_domains.0.name
}

data "oci_core_images" "images" {
	compartment_id=local.json_data.compartment_ocid
	shape = data.oci_core_shapes.shapes.shapes.7.name
}

resource "oci_core_instance" "VCN_1_Subnet_1_Instance_1" {
	availability_domain = data.oci_identity_availability_domains.oad.availability_domains.0.name
	compartment_id=local.json_data.compartment_ocid
	shape=data.oci_core_shapes.shapes.shapes.7.name
	create_vnic_details {
		subnet_id = oci_core_subnet.VCN_1_Subnet_1.id
	}
	display_name = "${local.json_data.last_name}_VCN_1_Subnet_1_Instance_1"
	metadata = {
		ssh_authorized_keys = local.json_data.public_ssh_key
	}
	source_details {
		source_id = data.oci_core_images.images.images[8].id
		source_type = "image"
	}
	provisioner "file" {
        	source = "${local.json_data.last_name}_ADB_Wallet.zip"
        	destination = "/home/opc/${local.json_data.last_name}_ADB_Wallet.zip"
        	connection {
        	        type = "ssh"
        	        user = "opc"
			private_key = local.json_data.private_ssh_key
        	host = oci_core_instance.VCN_1_Subnet_1_Instance_1.public_ip
        	}
	}
        provisioner "file" {
                source = "config.json"
                destination = "/home/opc/config.json"
                connection {
                        type = "ssh"
                        user = "opc"
                        private_key = local.json_data.private_ssh_key
                host = oci_core_instance.VCN_1_Subnet_1_Instance_1.public_ip
                }
        }
	provisioner "file" {
		source = "instantclient.zip"
		destination = "/home/opc/instantclient.zip"
		connection {
			type = "ssh"
			user = "opc"
			private_key = local.json_data.private_ssh_key
		host = oci_core_instance.VCN_1_Subnet_1_Instance_1.public_ip
		}
	}
        provisioner "remote-exec" {
                inline = ["sudo yum install python -y"]
                connection {
                        type = "ssh"
                        user = "opc"
			private_key = local.json_data.private_ssh_key
                host = oci_core_instance.VCN_1_Subnet_1_Instance_1.public_ip
                }
        }
	provisioner "local-exec" {
		command= "ansible-playbook ansible/johnston_ol.yaml -i '${oci_core_instance.VCN_1_Subnet_1_Instance_1.public_ip}', -u opc --private-key ${local.json_data.private_ssh_key_path}"
	}
        provisioner "file" {
                source = "python_scripts/johnston_select_demo.py"
                destination = "/home/opc/python_scripts/johnston_select_demo.py"
                connection {
                        type = "ssh"
                        user = "opc"
			private_key = local.json_data.private_ssh_key
                host = oci_core_instance.VCN_1_Subnet_1_Instance_1.public_ip
                }
        }
	preserve_boot_volume = false
	depends_on = [local_file.ADB_Wallet]
}
resource "azurerm_public_ip" "VN_1_Subnet_1_Instance_1_IP_1" {
	name = "${local.json_data.last_name}_VCN_1_Subnet_1_Instance_1_IP_1"
	location = azurerm_resource_group.OCI_Azure.location
	resource_group_name = azurerm_resource_group.OCI_Azure.name
	allocation_method = "Static"
}
resource "azurerm_network_interface" "VN_1_Subnet_1_Instance_1_NIC_1" {
	name = "${local.json_data.last_name}_VN_1_Subnet_1_Instance_1_NIC_1"
	location = azurerm_resource_group.OCI_Azure.location
	resource_group_name = azurerm_resource_group.OCI_Azure.name
	ip_configuration {
		name = "${local.json_data.last_name}_VN_1_Subnet_1_Instance_1_NIC_1_Config"
		subnet_id = azurerm_subnet.VN_1_Subnet_1.id
		private_ip_address_allocation = "Dynamic"
		public_ip_address_id = azurerm_public_ip.VN_1_Subnet_1_Instance_1_IP_1.id
	}
}
resource "azurerm_virtual_machine" "VN_1_Subnet_1_Instance_1" {
	name = "${local.json_data.last_name}_VN_1_Subnet_1_Instance_1"
	location = azurerm_resource_group.OCI_Azure.location
	resource_group_name = azurerm_resource_group.OCI_Azure.name
	network_interface_ids = [azurerm_network_interface.VN_1_Subnet_1_Instance_1_NIC_1.id]
	vm_size = "Standard_DS1_v2"
	delete_os_disk_on_termination = true
	delete_data_disks_on_termination = true
	storage_image_reference {
		publisher = "Canonical"
		offer = "UbuntuServer"
		sku = "18.04-LTS"
		version = "latest"
	}
	storage_os_disk {
		name = "JVN1S1I1-1"
		caching = "ReadWrite"
		create_option = "FromImage"
		managed_disk_type = "Standard_LRS"
	}
	os_profile {
		computer_name = "JVN1S1I1"
		admin_username = local.json_data.username
		admin_password = local.json_data.adb_password
	}
	os_profile_linux_config {
		disable_password_authentication = true
		ssh_keys {
			key_data = local.json_data.public_ssh_key
			path = "/home/${local.json_data.username}/.ssh/authorized_keys"
		}
	}
        provisioner "file" {
                source = "${local.json_data.last_name}_ADB_Wallet.zip"
                destination = "/home/${local.json_data.username}/${local.json_data.last_name}_ADB_Wallet.zip"
                connection {
                        type = "ssh"
                        user = local.json_data.username
                        private_key = local.json_data.private_ssh_key
                host = azurerm_public_ip.VN_1_Subnet_1_Instance_1_IP_1.ip_address
                }
        }
        provisioner "file" {
                source = "config.json"
                destination = "/home/${local.json_data.username}/config.json"
                connection {
                        type = "ssh"
                        user = local.json_data.username
                        private_key = local.json_data.private_ssh_key
                host = azurerm_public_ip.VN_1_Subnet_1_Instance_1_IP_1.ip_address
                }
        }
        provisioner "file" {
                source = "instantclient.zip"
                destination = "/home/${local.json_data.username}/instantclient.zip"
                connection {
                        type = "ssh"
                        user = local.json_data.username
                        private_key = local.json_data.private_ssh_key
                host = azurerm_public_ip.VN_1_Subnet_1_Instance_1_IP_1.ip_address
                }
        }
        provisioner "remote-exec" {
                inline = ["sudo apt install python","sudo chmod 777 /etc/hosts","echo ${data.oci_core_private_ips.adb_ip.private_ips.0.ip_address} ${oci_database_autonomous_database.ADW.private_endpoint} >> /etc/hosts"]
                connection {
                        type = "ssh"
                        user = local.json_data.username
                        private_key = local.json_data.private_ssh_key
                host = azurerm_public_ip.VN_1_Subnet_1_Instance_1_IP_1.ip_address
                }
        }
	provisioner "local-exec" {
		command= "ansible-playbook ansible/johnston_ubuntu.yaml -i '${azurerm_public_ip.VN_1_Subnet_1_Instance_1_IP_1.ip_address}', -u ${local.json_data.username} --private-key ${local.json_data.private_ssh_key_path}"
        }
        provisioner "file" {
                source = "python_scripts/johnston_ADB_table_creation.py"
                destination = "/home/${local.json_data.username}/python_scripts/johnston_ADB_table_creation.py"
                connection {
                        type = "ssh"
                        user = local.json_data.username
                        private_key = local.json_data.private_ssh_key
                host = azurerm_public_ip.VN_1_Subnet_1_Instance_1_IP_1.ip_address
                }
        }
        provisioner "file" {
                source = "python_scripts/johnston_select_demo.py"
                destination = "/home/${local.json_data.username}/python_scripts/johnston_select_demo.py"
                connection {
                        type = "ssh"
                        user = local.json_data.username
                        private_key = local.json_data.private_ssh_key
                host = azurerm_public_ip.VN_1_Subnet_1_Instance_1_IP_1.ip_address
                }
        }
        provisioner "remote-exec" {
                inline = ["python /home/${local.json_data.username}/python_scripts/johnston_ADB_table_creation.py"]
                connection {
                        type = "ssh"
                        user = local.json_data.username
                        private_key = local.json_data.private_ssh_key
                host = azurerm_public_ip.VN_1_Subnet_1_Instance_1_IP_1.ip_address
                }
        }
	depends_on = [local_file.ADB_Wallet,azurerm_virtual_network_gateway_connection.CX_1]
}
resource "oci_database_autonomous_database" "ADW" {
	admin_password = local.json_data.adb_password
	compartment_id = local.json_data.compartment_ocid
	cpu_core_count = 1
	data_storage_size_in_tbs = 1
	db_name = "${substr(local.json_data.last_name,0,1)}ADW01"
	display_name = "${local.json_data.last_name}_ADW_01"
	db_workload = "DW"
	nsg_ids=[oci_core_network_security_group.SG_1.id]
	subnet_id=oci_core_subnet.VCN_1_Subnet_2.id
}

data "oci_database_autonomous_data_warehouse_wallet" "ADB_Wallet" {
	autonomous_data_warehouse_id = oci_database_autonomous_database.ADW.id
	password = local.json_data.adb_password
	base64_encode_content = "true"
}

resource "local_file" "ADB_Wallet" {
	content_base64 = data.oci_database_autonomous_data_warehouse_wallet.ADB_Wallet.content
	filename = "${local.json_data.last_name}_ADB_Wallet.zip"
}
output "oci_vm" {
	value = oci_core_instance.VCN_1_Subnet_1_Instance_1.public_ip
}
output "azure_vm" {
	value = azurerm_public_ip.VN_1_Subnet_1_Instance_1_IP_1.ip_address
}
data "oci_core_private_ips" "adb_ip" {
    subnet_id = oci_core_subnet.VCN_1_Subnet_2.id
    depends_on = [oci_database_autonomous_database.ADW]
}
output "adb"{
	value = data.oci_core_private_ips.adb_ip.private_ips.0.ip_address
}
