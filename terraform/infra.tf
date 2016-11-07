
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-cf1b05ab"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "default_ig"
  }
}

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


#****creates private subnets***** 
resource "aws_subnet" "private_subnet_a"{
   vpc_id = "${var.vpc_id}"
   cidr_block = "172.31.0.0/22"
   availability_zone = "us-west-2a"
   map_public_ip_on_launch = false
   
  tags { 
     Name = "private_a"
   }
}

resource "aws_subnet" "private_subnet_b"{
   vpc_id = "${var.vpc_id}"
   cidr_block = "172.31.4.0/22"
   availability_zone = "us-west-2b"
   map_public_ip_on_launch = false
   
  tags { 
     Name = "private_b"
   }
}
     
resource "aws_subnet" "private_subnet_c"{
   vpc_id = "${var.vpc_id}"
   cidr_block = "172.31.8.0/22"
   availability_zone = "us-west-2c"
   map_public_ip_on_launch = false
   
  tags {  
     Name = "private_c"
  }
}
          
    
#*****creates public subnets******    
resource "aws_subnet" "public_subnet_a" {
   vpc_id = "${var.vpc_id}"
   cidr_block = "172.31.10.0/24"
   availability_zone = "us-west-2a"
   depends_on = ["aws_internet_gateway.gw"]
   map_public_ip_on_launch = true

   tags {
      Name = "public_a"
    }
}

recource "aws_subnet" "public_subnet_b"{
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.11.0/24"
  availability_zone = "us_west-2b"
  depends_on = ["aws_internet_gateway.gw"]
  map_public_ip_on_launch = true
 
  tags{ 
      Name = "public_b"
   }
}  
     
      
recourse "aws_subnet" "public_subnet_c"{
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.12.0/24"
  availability_zone = "us_west-2c"
  depends_on = ["aws_internet_gateway.gw"]
  map_public_ip_on_launch = true

   tags { 
       Name = "public_c"
   }
}

resource "aws_route_table_association" "public_subnet_a_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}


resource "aws_route_table_association" "public_subnet_b_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_b.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}


resource "aws_route_table_association" "public_subnet_c_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_c.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_a_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_a.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}


resource "aws_route_table_association" "private_subnet_b_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}


resource "aws_route_table_association" "private_subnet_c_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"


resource = "aws_eip" "nat" {
   vpc = true
} 

resource "aws_nat_gateway" "gw" {
   allocation_id = "${aws.eip.nat.id}"
   subnet_id = "${aws_subnet.public_subnet_a.id}"
   depends_on = ["aws_internet_gateway.gw"]
}


resource "aws_security_group" "secgrp" {
  vpc_id = "${var.vpc_id}

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

resource "aws_eip" "bastion" { 
  instance = "{$aws_instance.bastion.id}
  vpc = true
}

resource "aws_instance" "bastion" {
   ami = "ami-b04e92d0"
   instance_type = "t2.micro"
   subnet_id = "${aws_subnet_public_subnet_a.id}"
   sucurity_groups = ["${aws.subnet.public_subnet_a.id}"]
   key_name = "cit360"



