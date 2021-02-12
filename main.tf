#.\terraform plan 
#.\terraform apply
#.\terraform destroy
#.\terraform destroy -target aws_instance.test

provider "aws" {
        region                  = "us-east-1"
        shared_credentials_file = "credentials.txt"
        profile                 = "default"
}

resource "aws_key_pair" "awskey" {
  key_name   = "AWSKEY"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAkz2xT7guXfjyBEsYR+gNVgDaf3H6U/X+1F+X0+DIPqX4LStA7RClzpxlxzJQ4pXxLccu11WeRwXkYYKEi1sn4icHyAL4U3pzV1Mw1Q6LlXLczUrBhOIuVcNxSUpHiwSiFjUClDYUu2t68gUwiHyFRPt6BaurzjNUf5JrQoNlJbZSmzquVaNkp4KjJ9Hn5YaV2TgQaZ4tCej9Vggv0om8inoKyJ38cCIeDsNeU7/WUXnPIKPnO7/gzXmZ5hwzBxnP6awFWeOzIfCMmFC1ttEOGhz/eWin1tjNLxkadWE+PFwGmKB5wBMWrmQu6PctlbJaKN56pY52U+PHONlFd2FkXw== rsa-key-20200303"
}

locals {
  //key_name  = "AWSKEY" //Key name already imported
  key_name  = aws_key_pair.awskey.id 
}

// dhcp
	resource "aws_vpc_dhcp_options" "dhcpskills" {
		domain_name          = "skills.pt"
		domain_name_servers  = ["172.16.0.100", "1.1.1.1"]

		tags = {
			Name = "dhcpskills"
		}
	}
	
	resource "aws_vpc_dhcp_options" "dhcpeuroskills" {
		domain_name          = "euroskills.com"
		domain_name_servers  = ["172.17.0.100", "1.1.1.1"]

		tags = {
			Name = "dhcpeuroskills"
		}
	}

// VPC & subnet
	resource "aws_vpc" "skills" {
	  	cidr_block = "172.16.0.0/16"
		
		enable_dns_hostnames = true
	  	tags = {
	    	Name = "skills.pt"
	    }
	}
	
	resource "aws_subnet" "subskills-hq-dmz" {
		vpc_id     = aws_vpc.skills.id
	  cidr_block = "172.16.0.0/24"
		availability_zone = "us-east-1a"
	  tags = {
	    	Name = "sub-172.16.0"
	  }
	}
	
	resource "aws_subnet" "subskills-cli" {
	  	vpc_id     = aws_vpc.skills.id
	  	cidr_block = "172.16.1.0/24"
		availability_zone = "us-east-1a"


	  	tags = {
	  	  Name = "sub-172.16.1"
	  	}
	}
	
	resource "aws_vpc" "euroskills" {
	  	cidr_block = "172.17.0.0/16"
		enable_dns_hostnames = true
	  	tags = {
	    	Name = "euroskills.com"
	    }
	}
	
	
	resource "aws_subnet" "subeuroskills-sk" {
		vpc_id     = aws_vpc.euroskills.id
	  	cidr_block = "172.17.0.0/24"
		availability_zone = "us-east-1b"

	  	tags = {
	    	Name = "sub-172.17.0"
	  	}
	}
	resource "aws_subnet" "subeuroskills-skills" {
		vpc_id     = aws_vpc.euroskills.id
	  	cidr_block = "172.17.1.0/24"
		availability_zone = "us-east-1b"
	  	tags = {
	    	Name = "sub-172.17.1"
	  	}
	}

// 	DHCP association
	resource "aws_vpc_dhcp_options_association" "dhcpskills" {
		vpc_id          = aws_vpc.skills.id
		dhcp_options_id = aws_vpc_dhcp_options.dhcpskills.id
		}
	resource "aws_vpc_dhcp_options_association" "dhcpeuroskills" {
		vpc_id          = aws_vpc.euroskills.id
		dhcp_options_id = aws_vpc_dhcp_options.dhcpeuroskills.id
		}

// 	Internet Gateway
	resource "aws_internet_gateway" "gwskills" {
	  vpc_id = aws_vpc.skills.id
	
	  tags = {
	    Name = "gwskills"
	  }
	}
	
	resource "aws_internet_gateway" "gweuroskills" {
	  vpc_id = aws_vpc.euroskills.id
	
	  tags = {
	    Name = "gweuroskills"
	  }
	}
	
// 	Route
	resource "aws_route_table" "rsub172-16-0" {
	  	vpc_id = aws_vpc.skills.id
	  	
	
	  	route {
	    	cidr_block = "0.0.0.0/0"
	    	gateway_id = aws_internet_gateway.gwskills.id
	  	}
	
	  	tags = {
	    	Name = "rsub172.16.0"
	  	}
	}
	resource "aws_route_table" "rsub172-16-1" {
	  	vpc_id = aws_vpc.skills.id
	
	  	route {
	    	cidr_block = "0.0.0.0/0"
	    	network_interface_id = aws_network_interface.rtrhqin2.id
	  	}
	
	  	tags = {
	  	  Name = "rsub172.16.1"
	  	}
	}
	
	
	resource "aws_route_table" "rsub172-17-0" {
	  	vpc_id = aws_vpc.euroskills.id
	
	  	route {
	    	cidr_block = "0.0.0.0/0"
	   		gateway_id = aws_internet_gateway.gweuroskills.id
	  	}
	
		tags = {
	   	  Name = "rsub172.17.0"
		}
	}
	resource "aws_route_table" "rsub172-17-1" {
	  	vpc_id = aws_vpc.euroskills.id
	
	  	route {
	    	cidr_block = "0.0.0.0/0"
	    	network_interface_id = aws_network_interface.rtrskin2.id
	  	}
	
	  	tags = {
	  	  Name = "rsub172.17.1"
	  	}
	}

// route_table_association
	resource "aws_route_table_association" "rsub172-16-0" {
		subnet_id = aws_subnet.subskills-hq-dmz.id
		route_table_id = aws_route_table.rsub172-16-0.id
	}

	resource "aws_route_table_association" "rsub172-16-1" {
		subnet_id = aws_subnet.subskills-cli.id
		route_table_id = aws_route_table.rsub172-16-1.id
	}

	resource "aws_route_table_association" "rsub172-17-0" {
		subnet_id = aws_subnet.subeuroskills-sk.id
		route_table_id = aws_route_table.rsub172-17-0.id
	}

	resource "aws_route_table_association" "rsub172-17-1" {
		subnet_id = aws_subnet.subeuroskills-skills.id
		route_table_id = aws_route_table.rsub172-17-1.id
	}


// 	security group
	resource "aws_security_group"  "sgall_skills" {
		vpc_id = aws_vpc.skills.id
		name = "allow_all_skills"
	
		ingress {
		    protocol  = -1
		    self      = true
		    from_port = 0
		    to_port   = 0
		    cidr_blocks = ["0.0.0.0/0"]
		}
	
		egress {
		    from_port   = 0
		    to_port     = 0
		    protocol    = "-1"
		    cidr_blocks = ["0.0.0.0/0"]
		  }
		}

	resource "aws_security_group"  "sgall-euroskills" {
		vpc_id =  aws_vpc.euroskills.id
		name = "allow_all_euroskills"
	
	  ingress {
	    protocol  = -1
	    self      = true
	    from_port = 0
	    to_port   = 0
	    cidr_blocks = ["0.0.0.0/0"]
	  }
	
	  egress {
	    from_port   = 0
	    to_port     = 0
	    protocol    = "-1"
	    cidr_blocks = ["0.0.0.0/0"]
	  }
	}

// instance RTRHQ + EIP + add Network
	resource "aws_instance" "rtrhq" {
	    ami = "ami-0ab8c4a638961d774"
	    instance_type = "t2.micro"
	    key_name  = local.key_name
	
	    associate_public_ip_address  = false
	    private_ip = "172.16.0.100"
	    subnet_id  = aws_subnet.subskills-hq-dmz.id
	   	source_dest_check = false
	  	security_groups = [aws_security_group.sgall_skills.id]
	
	    tags = {
	    	Name = "RTRHQ"
	    }
	
	    root_block_device {
	        delete_on_termination = true
	        volume_size = 8
	        volume_type = "gp2"
	        }
	
	    ebs_block_device {
	        device_name = "/dev/sdg"
	        delete_on_termination = true
	        volume_size = 16
	        volume_type = "gp2"
	        }
	
	}
	

	resource "aws_network_interface" "rtrhqin2" {
	  	subnet_id       = aws_subnet.subskills-cli.id
	  	private_ips     = ["172.16.1.100"]
	  	security_groups = [aws_security_group.sgall_skills.id]
	  	source_dest_check = false
	 	tags = {
	    	Name = "rtrhqin2"
	    }
	
	    attachment {
	    	instance     = aws_instance.rtrhq.id
	    	device_index = 1
	  }
	}

	#Elastic IP
	resource "aws_eip" "ippub_rtrhq" {
	  	vpc = true
	}
	
	resource "aws_eip_association" "ippub_rtrhq_assoc" {
		instance_id   = aws_instance.rtrhq.id
	  	allocation_id = aws_eip.ippub_rtrhq.id
	  	private_ip_address = "172.16.0.100"
	}  	

// instance DMZ 
	resource "aws_instance" "dmzhq" {
	    ami = "ami-0e3e4fb766bce8790"
	    instance_type = "t2.micro"
	    key_name  = local.key_name
	
	    associate_public_ip_address  = false
	    private_ip = "172.16.0.101"
	    subnet_id  = aws_subnet.subskills-hq-dmz.id
	   	source_dest_check = false
	  	security_groups = [aws_security_group.sgall_skills.id]
			
	    tags = {
	    	Name = "DMZHQ"
	    }
	
	    root_block_device {
	        delete_on_termination = true
	        volume_size = 8
	        volume_type = "gp2"
	        }
	
	    ebs_block_device {
	        device_name = "/dev/sdg"
	        delete_on_termination = true
	        volume_size = 16
	        volume_type = "gp2"
	        }
	
	}
	

// instance CLI 
	resource "aws_instance" "clihq" {
	    ami = "ami-0d92bded3fd242612"
	    instance_type = "t2.micro"
	    key_name  = local.key_name
	
	    associate_public_ip_address  = false
	    private_ip = "172.16.1.101"
	    subnet_id  = aws_subnet.subskills-cli.id
	   	source_dest_check = false
	  	security_groups = [aws_security_group.sgall_skills.id]

	    tags = {
	    	Name = "CLIHQ"
	    }
	
	    root_block_device {
	        delete_on_termination = true
	        volume_size = 8
	        volume_type = "gp2"
	        }
	
	    ebs_block_device {
	        device_name = "/dev/sdg"
	        delete_on_termination = true
	        volume_size = 16
	        volume_type = "gp2"
	        }
	
	}
	
// instance RTRSK + EIP + add Network
	resource "aws_instance" "rtrsk" {
	    ami = "ami-0794f88d451466e95"
	    instance_type = "t2.micro"
	    key_name  = local.key_name
	
	    associate_public_ip_address  = false
	    private_ip = "172.17.0.100"
	    subnet_id  = aws_subnet.subeuroskills-sk.id
	   	source_dest_check = false
	  	security_groups = [aws_security_group.sgall-euroskills.id]
	
	    tags = {
	    	Name = "RTRSK"
	    }
	
	    root_block_device {
	        delete_on_termination = true
	        volume_size = 8
	        volume_type = "gp2"
	        }
	
	    ebs_block_device {
	        device_name = "/dev/sdg"
	        delete_on_termination = true
	        volume_size = 16
	        volume_type = "gp2"
	        }
	
	}
	

	resource "aws_network_interface" "rtrskin2" {
	  	subnet_id       = aws_subnet.subeuroskills-skills.id
	  	private_ips     = ["172.17.1.100"]
	  	security_groups = [aws_security_group.sgall-euroskills.id]
	  	source_dest_check = false
	 		tags = {
	    	Name = "rtrskin2"
	    }
	
	    attachment {
	    	instance     = aws_instance.rtrsk.id
	    	device_index = 1
	  	}
	}

	#Elastic IP
	resource "aws_eip" "ippub_rtrsk" {
	  vpc = true
	}
	
	resource "aws_eip_association" "ippub_rtrsk_assoc" {
		instance_id   = aws_instance.rtrsk.id
	  allocation_id = aws_eip.ippub_rtrsk.id
	  private_ip_address = "172.17.0.100"
	}  	


// 	instance Skills 
	resource "aws_instance" "skills" {
	    ami = "ami-0ae7cf81e2372b926"
	    instance_type = "t2.micro"
	    key_name  = local.key_name
	
	    associate_public_ip_address  = false
	    private_ip = "172.17.1.101"
	    subnet_id  = aws_subnet.subeuroskills-skills.id
	   	source_dest_check = false
	  	security_groups =  [aws_security_group.sgall-euroskills.id]
	
	    tags = {
	    	Name = "EUROSKILLS"
	    }
	
	    root_block_device {
	        delete_on_termination = true
	        volume_size = 8
	        volume_type = "gp2"
	        }
	
	    ebs_block_device {
	        device_name = "/dev/sdg"
	        delete_on_termination = true
	        volume_size = 16
	        volume_type = "gp2"
	        }
	}