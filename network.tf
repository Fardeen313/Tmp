provider "aws" {
  region="us-east-1"
}
terraform {
  backend "s3" {
    bucket = "fardeen313"
    key = "zone/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }
}
# vpc
resource "aws_vpc" "name" {
  tags = {
    Name = "custom_vpc"
    Environment = "test"
  }
  cidr_block = "10.0.0.0/22"
}
output "vpc_id" {
  value = aws_vpc.name.id
}
resource "aws_internet_gateway" "name" {
  vpc_id = aws_vpc.name.id
  tags = {
    Name = "cust-ig"
  }
}
resource "aws_subnet" "name" {
  vpc_id = aws_vpc.name.id
  cidr_block = "10.0.0.0/26"
  availability_zone = "us-east-1a"
  tags = {
    Name="custom_subnet"
  }
}
resource "aws_route_table" "name" {
  vpc_id = aws_vpc.name.id
  route {
    gateway_id = aws_internet_gateway.name.id
    cidr_block = "0.0.0.0/0"
  }
}
resource "aws_route_table_association" "name" {
  route_table_id = aws_route_table.name.id
  subnet_id = aws_subnet.name.id
}
resource "aws_security_group" "name" {
  name = "cust_sg"
  description = "allow HTTP,SSH"
  vpc_id = aws_vpc.name.id
  ingress {
    description = "allow ssh 22"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "106.221.208.124/32" ]
  }
  ingress {
    description = "allow HTTP 80"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "106.221.208.124/32" ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  tags = {
    Environment="test"
  }

}
resource "aws_instance" "name" {
  ami = "ami-02457590d33d576c3"
  key_name = "public"
  subnet_id = aws_subnet.name.id
  associate_public_ip_address = true
  security_groups = [ aws_security_group.name.id ]
  instance_type = "t2.micro"
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              echo "<h1>Welcome to COVERBAZAR Cloud Server</h1>" > /var/www/html/index.html
              EOF
  tags = {
    Name="sample"
  }
}
output "pvt_dns" {
  value = aws_instance.name.private_dns
}
output "pvt_ip" {
  value = aws_instance.name.private_ip
  sensitive = true
}