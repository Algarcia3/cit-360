
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-cf1b05ab"
}

#Decalres var "password" 
variable "password" {
  description = "password for usage of the RDS instance" 
}

#Sets provider to "aws" and region to "us-west-2"
provider "aws" {
  region = "us-west-2"
}

#Sets the VPC to 172.31.0.0/16
resource "aws_vpc" "main" {
  cidr_block = "172.31.0.0/16"
}

#Creates a VPC Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "default_ig"
  }
}

#Creates a NAT gateway with subnet_id of "aws_subnet.public_subnet_a"
resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  depends_on = ["aws_internet_gateway.gw"]
}

#Creates an Elastic IP to be attached to the NAT Gateway
resource "aws_eip" "nat" {
  vpc = true
}

#Creates an Elastic IP to be attached to the bastion instance
resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc = true
}

#Creates a public subnet
resource "aws_subnet" "public_subnet_a" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.20.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.gw"]

  tags {
     Name = "public_a"
    }
}

#Creates a public subnet
resource "aws_subnet" "public_subnet_b" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.21.0/24"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.gw"]

  tags {
     Name = "public_b"
  }
}

#Creates a public subnet
resource "aws_subnet" "public_subnet_c" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.22.0/24"
  availability_zone = "us-west-2c"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.gw"]

  tags {
    Name = "public_c"
  }
}

#Creates a public route table in aws with the Internet Gateway
resource "aws_route_table" "public_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public_routing_table"
  }
}

#assosciates public_subnet_a to aws_route_table.public_routing_table
resource "aws_route_table_association" "public_subnet_a_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

#assosciates public_subnet_b to aws_route_table.public_routing_table
resource "aws_route_table_association" "public_subnet_b_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_b.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

#assosciates public_subnet_c to aws_route_table.public_routing_table
resource "aws_route_table_association" "public_subnet_c_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_c.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

#Creates a private subnet
resource "aws_subnet" "private_subnet_a" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.0.0/22"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = false
  tags {
    Name = "private_a"
  }
}

#Creates a private subnet
resource "aws_subnet" "private_subnet_b" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.4.0/22"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = false
  
  tags {
    Name = "private_b"
  }
}

#Creates a private subnet
resource "aws_subnet" "private_subnet_c" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.8.0/22"
  availability_zone = "us-west-2c"
  map_public_ip_on_launch = false

  tags {
    Name = "private_c"
  }
}

#Creates a private routing table in aws with the NAT Gateway
resource "aws_route_table" "private_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
  cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.gw.id}"
  }

  tags {
    Name = "private_routing_table"
  }
}

#assosciates private_subnet_a to aws_route_table.private_routing_table
resource "aws_route_table_association" "private_subnet_a_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_a.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

#assosciates private_subnet_b to aws_route_table.private_routing_table
resource "aws_route_table_association" "private_subnet_b_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

#assosciates private_subnet_c to aws_route_table.private_routing_table
resource "aws_route_table_association" "private_subnet_c_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

#allows access from SSH to current IP address
resource "aws_security_group" "ssh" {
  vpc_id = "${var.vpc_id}"
  description = "SSH security group"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security group that allows port 22 within the VPC 
resource "aws_security_group" "rds" {
  vpc_id = "${var.vpc_id}"
  description = "RDS security group"
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }
   egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security group for the instances that allows port 80 and 22 within the VPC
resource "aws_security_group" "web" {
  vpc_id = "${var.vpc_id}"
  description = "VPC Instance security group"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${aws_vpc.main.cidr_block}"] 
  }

   egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }  
}

#Security group for ELB that allows port 80 within the VPC
resource "aws_security_group" "elb" {
  description = "ELB security group"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

#Creates a DB subnet group that references private_subnet_a and private_subnet_b
resource "aws_db_subnet_group" "main" {
  name = "main"
  subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]
  tags {
    Name = "Db subnet group"
  }
}

resource "aws_elb" "web" {
  name = "public-elb"
  subnets = ["${aws_subnet.public_subnet_b.id}", "${aws_subnet.public_subnet_c.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/"
    interval = 30
  }
  
  instances = ["${aws_instance.webserverb.id}", "${aws_instance.webserverc.id}"] 
  connection_draining = true
  connection_draining_timeout = 60
  
  tags {
    Name = "public-elb"
  } 
}

#Creates a single bastion EC2 instance in public_subnet_a with keypair cit360
resource "aws_instance" "bastion" {
  ami = "ami-b04e92d0"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  security_groups = ["${aws_security_group.ssh.id}"]
  key_name = "cit360"

#Connects to a remote node in the EC2 Instance and installs pip and ansible
  provisioner "remote-exec" {
    inline = [ 
    "sudo easy_install pip",
    "sudo pip install paramiko PyYAML Jinja2 httplib2 six",
    "sudo pip install ansible"
    ]

#Makes the connection to the EC2 Instance via ssh and gives it the cit360 key
    connection {
      type = "ssh"
      user = "ec2-user"
      agent = "false"
      private_key = "${file("/Users/alfredogarcia/cit-360/terraform/cit360.pem")}"
    }
  }

#Copies the directory "ansible" into the EC2 Instance
  provisioner "file" {
    source = "/Users/alfredogarcia/cit-360/ansible"
    destination = "/home/ec2-user/"

#Makes the connection to the EC2 Instance via ssh and gives it the cit360 key 
    connection {
      type = "ssh"
      user = "ec2-user"
      agent = "false"
      private_key = "${file("/Users/alfredogarcia/cit-360/terraform/cit360.pem")}"
    }
  }

#Copies the cit360 key to the EC2 Instance to deploy web.yml playbook
  provisioner "file" {
    source = "/Users/alfredogarcia/cit-360/terraform/cit360.pem"
    destination = "/home/ec2-user/.ssh/cit360.pem"

#Makes the connection to the EC2 Instance via ssh and gives it the cit360 key
     connection {
      type = "ssh"
      user = "ec2-user"
      agent = "false"
      private_key = "${file("/Users/alfredogarcia/cit-360/terraform/cit360.pem")}"
    }
  }

  tags {
    Name = "bastion"
    }
}

#Creates a single t2.micro instance in private_subnet_c with keypair cit360
resource "aws_instance" "webserverb" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  associate_public_ip_address = false
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  security_groups = ["${aws_security_group.web.id}"]
  key_name = "cit360"
  tags {
    Name = "webserver-b"
    Service = "curriculum"
  }
}

#Creates a single t2.micro instance in private_subnet_c with keypair cit360
resource "aws_instance" "webserverc" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  associate_public_ip_address = false
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  security_groups = ["${aws_security_group.web.id}"]
  key_name = "cit360"
  tags {
    Name = "webserver-c"
    Service = "curriculum"
  }
}

#Creates a single DB instance as an RDS with mariadb as a type
resource "aws_db_instance" "rds" {
  identifier = "rds"
  allocated_storage = 5
  storage_type = "gp2"
  engine = "mariadb"
  engine_version = "10.0.24"
  instance_class = "db.t2.micro"
  multi_az = "false"
  name = "RDS"
  username = "root"
  password = "${var.password}"
  publicly_accessible = false
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.main.id}"
}
