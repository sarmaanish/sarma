terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}

#Public Subnet

resource "aws_subnet" "Publicsubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1a"
  
  tags = {
    Name = "Publicsubnet"
  }
}

#Private Subnet

resource "aws_subnet" "Privatesubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-1b"
  
  tags = {
    Name = "Privatesubnet"
  }
}

#IGW

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myigw"
  }
}

#Public Route Table

resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "PublicRT"
  }
}

#Public Route Table Association

resource "aws_route_table_association" "PublicRTAssoc" {
  subnet_id      = aws_subnet.Publicsubnet.id
  route_table_id = aws_route_table.PublicRT.id
}

#EIP

resource "aws_eip" "myeip" {
 vpc      = true

tags = {
    Name = "myeip"
  }
}

#NAT

resource "aws_nat_gateway" "mynat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.Publicsubnet.id

  tags = {
    Name = "mynat"
  }
}

#Private Route Table

resource "aws_route_table" "PrivateRT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.mynat.id
  }

  tags = {
    Name = "PrivateRT"
  }
}

#Private Route Table Association

resource "aws_route_table_association" "PrivateRTAssoc" {
  subnet_id      = aws_subnet.Privatesubnet.id
  route_table_id = aws_route_table.PrivateRT.id
}

#Public Security Group

resource "aws_security_group" "PublicSG" {
  name        = "PublicSG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PublicSG"
  }
}

#Private Security Group

resource "aws_security_group" "PrivateSG" {
  name        = "PrivateSG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["10.0.1.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrivateSG"
  }
}

#Public Instance

resource "aws_instance" "public_instance" {
  ami                                             = "ami-06c2ec1ceac22e8d6"
  instance_type                                   = "t3.micro"
  availability_zone                               = "ap-south-1a"
  associate_public_ip_address                     = "true"
  vpc_security_group_ids                          = [aws_security_group.PublicSG.id]
  subnet_id                                       = aws_subnet.Publicsubnet.id 
  key_name                                        = "sarmaanish"
  
    tags = {
    Name = "HDFCBANK WEBSERVER"
  }
}

#Private Instance

resource "aws_instance" "private_instance" {
  ami                                             = "ami-06c2ec1ceac22e8d6"
  instance_type                                   = "t3.micro"
  availability_zone                               = "ap-south-1c"
  associate_public_ip_address                     = "false"
  vpc_security_group_ids                          = [aws_security_group.PrivateSG.id]
  subnet_id                                       = aws_subnet.Privatesubnet.id 
  key_name                                        = "sarmaanish"
  
    tags = {
    Name = "HDFCBANK WEBSERVER"
  }
}
