## Todo's and Issues
/*
Issues
. Issue 1
  blanco main route table with no subnet association is default created when creating a vpc
  you could refernce it with either default_route_table_id or main_route_table_id 
  Howto get these id and reference them in the association rt subnet assoctaion
  howto tag this default created rt - it should replace the localrt
  ??using data blocks??
  Note that you also receive a default security group 
. Issue 2
  Deviated values for the ingres ICMP rule
. Issue 3
  The Terraform destroy command does not stop/remove running databases and therefore the destroy fails and subsequently not all resources are removed
  Workaround 1st delete! the database before running the terraform destroy command
Todo's
. More Dynamic
.. Solve the blanco default created route table, see above
.. usage of maps 
.. concat (e.g. pre-fix for name tags) see also https://www.terraform.io/docs/configuration/functions/concat.html
   results in  
   error: Invalid function argument
  on awsvpcec2rds.tf line 87, in resource "aws_vpc" "fb_vpc":
  87:     Name = tostring(concat(var.pre_fix, "vpc"))
    |----------------
    | var.pre_fix is "fb_"
    Invalid value for "seqs" parameter: all arguments must be lists or tuples; got string.
. Subsequent to be created AWS Primary Resources
.. S3
.. Resource groups
.. LoadBalancer
.. EFS and association with two ec2 instance
. Secondary Resources
.. EBS Block storage attached to an ec2 instance
. Organization
.. Multiple TF files
. Limitations
.. (custom) AMI's are now region specific - by copying the AMI's to other regions then also runnable in other regions
. Misc
.. usage of Provisioning (running shell scripts)
   https://learn.hashicorp.com/terraform/getting-started/provision
.. Usage of Terraform modules source: 
  e.g. source = "terraform-aws-modules/vpc/aws" 
  usage of github?
  usage of s3
Verification
. 
Links
. Search for "terraform resource aws_internet_gateway, vpc" to receive the full options for each AWS resource
  https://www.terraform.io/docs/providers/aws/r/internet_gateway.html
  can be repated for each aws resource
*/
/*
region    = "eu-central-1"
profile   = "default"
key_name  = "fbkeypair" 
cidrs     = ["10.0.0.0/16", "10.1.0.0/16"]
az1a      = "eu-central-1a"
az1b      = "eu-central-1b"
az1c      = "eu-central-1c"
my_ip     = ["62.251.83.160/32"]
vpc_cidr   = "10.90.0.0/16"
pubsn_cidr = "10.90.0.0/24"
privsnas1_cidr = "10.90.1.0/24"
privsnas2_cidr = "10.90.2.0/24"
privsnrds1_cidr = "10.90.3.0/24"
privsnrds2_cidr = "10.90.4.0/24"
*/
# variable section
variable "region" {}
variable "profile" {}
variable "key_name" {}
variable "cidrs" {type = list}
variable "vpc_cidr" {}
variable "pubsn_cidr" {}
variable "privsnas1_cidr" {}
variable "privsnas2_cidr" {}
variable "privsnrds1_cidr" {}
variable "privsnrds2_cidr" {}
variable "az1a" {}
variable "az1b" {}
variable "az1c" {}
variable "my_ip" {type = list}
variable "pre_fix" {}
variable "vpc_name" {}
# Provider and aws credentials and region settings
provider "aws" {
  profile    = var.profile
  region     = var.region
}
# Create a new vpc
resource "aws_vpc" "fb_vpc" {
  cidr_block       = var.vpc_cidr
  tags = {
    Name = var.vpc_name
    #Name = tostring(concat(var.pre_fix, "vpc")) does not work, see above
  }
}
# Create a new igw
resource "aws_internet_gateway" "fb_igw" {
  vpc_id = aws_vpc.fb_vpc.id
  tags = {
    Name = "fb_igw"
  }
}
# Create a new ngw
resource "aws_nat_gateway" "fb_ngw" {
  allocation_id = aws_eip.fb_eip.id
  subnet_id     = aws_subnet.fb_publicsubnet.id
  tags = {
    Name = "fb_ngw"
  }
}
# Create a public subnet
resource "aws_subnet" "fb_publicsubnet" {
   vpc_id                  = aws_vpc.fb_vpc.id
   cidr_block              = var.pubsn_cidr
   availability_zone       = var.az1a 
   map_public_ip_on_launch = true
  tags = {
    Name = "fb_publicsubnet"
  }
}
# Create a private subnet for Application Server as1
resource "aws_subnet" "fb_privsnas1" {
   vpc_id            = aws_vpc.fb_vpc.id
   cidr_block        = var.privsnas1_cidr
   availability_zone = var.az1a 
  tags = {
    Name = "fb_privsnas1"
  }
}
# Create a private subnet for Application Server as2
resource "aws_subnet" "fb_privsnas2" {
   vpc_id            = aws_vpc.fb_vpc.id
   cidr_block        = var.privsnas2_cidr
   availability_zone = var.az1b 
  tags = {
    Name = "fb_privsnas2"
  }
}
# Create a private subnet for RDS1
resource "aws_subnet" "fb_privsnrds1" {
   vpc_id            = aws_vpc.fb_vpc.id
   cidr_block        = var.privsnrds1_cidr
   availability_zone = var.az1a 
  tags = {
    Name = "fb_privsnrds1"
  }
}
# Create a private subnet for RDS2
resource "aws_subnet" "fb_privsnrds2" {
   vpc_id            = aws_vpc.fb_vpc.id
   cidr_block        = var.privsnrds2_cidr
   availability_zone = var.az1b 
  tags = {
    Name = "fb_privsnrds2"
  }
}

# Create a new AWS eip
resource "aws_eip" "fb_eip" {
    vpc           = true
  tags = {
    Name = "fb_eip"
  }
}
# Create a AWS igw route table
resource "aws_route_table" "fb_igwrt" {
  vpc_id = aws_vpc.fb_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fb_igw.id
  }
  tags = {
    Name = "fb_igwrt"
  }
}
# create association between public subnet and IGW_RT
resource "aws_route_table_association" "public_igw" {
  subnet_id      = aws_subnet.fb_publicsubnet.id
  route_table_id = aws_route_table.fb_igwrt.id
}

# Create a AWS nat route table
resource "aws_route_table" "fb_natrt" {
  vpc_id = aws_vpc.fb_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.fb_ngw.id
  }
  tags = {
    Name = "fb_natrt"
  }
}
# create association between private as1 and NAT_RT
resource "aws_route_table_association" "privatas1_natrt" {
  subnet_id      = aws_subnet.fb_privsnas1.id
  route_table_id = aws_route_table.fb_natrt.id
}
# create association between private as2 and NAT_RT
resource "aws_route_table_association" "privatas2_natrt" {
  subnet_id      = aws_subnet.fb_privsnas2.id
  route_table_id = aws_route_table.fb_natrt.id
}
#retreive default created route table via default_route_table_id or main_route_table_id
/*
data "aws_route_table" "fb_defaultrt" {
  filter {
    route_table_id = main_route_table_id 
  }
}  
variable default_route_table_id {}
default_route_table_id = main_route_table_id 

data "aws_route_table" "fb_defaultrt" {
  route_table_id = var.default_route_table_id
}
# create association between private subnet rds1 and local_RT
resource "aws_route_table_association" "privatrds1_lclrt" {
  subnet_id      = aws_subnet.fb_privsnrds1.id
  route_table_id = data.aws_route_table.fb_defaultrt.id
}
# create association between private subnet rds2 and local_RT
resource "aws_route_table_association" "privatrds2_lclrt" {
  subnet_id      = aws_subnet.fb_privsnrds2.id
  route_table_id = data.aws_route_table.fb_defaultrt.id
}
*/
# Create a local route table
resource "aws_route_table" "fb_localrt" {
  vpc_id = aws_vpc.fb_vpc.id
  tags = {
    Name = "fb_localrt"
  }
}
# create association between private subnet rds1 and local_RT
resource "aws_route_table_association" "privatrds1_lclrt" {
  subnet_id      = aws_subnet.fb_privsnrds1.id
  route_table_id = aws_route_table.fb_localrt.id
}
# create association between private subnet rds2 and local_RT
resource "aws_route_table_association" "privatrds2_lclrt" {
  subnet_id      = aws_subnet.fb_privsnrds2.id
  route_table_id = aws_route_table.fb_localrt.id
}
# Create bh security group and ingress/egress rules
resource "aws_security_group" "fb_secgrpbh" {
    description = "BastionHostSecurityGroup"
    name = "fb_secgrpbh"
    vpc_id      = aws_vpc.fb_vpc.id
    tags = {
    Name = "fb_secgrpbh"
  }
  ingress {
    # SSH
    from_port    = 22
    to_port      = 22
    protocol     = "TCP"
    description  = "SSH"
    cidr_blocks = var.my_ip
  }
  ingress {
    # RDP
    from_port   = 3389
    to_port     = 3389
    protocol    = "TCP"
    description  = "RDP"
    cidr_blocks = var.my_ip
  }
  ingress {
    # ICMP - results in deviated values for type ("Custom ICMP Rule - IPv4" <-"All ICMP - IPv4"), protocol ("Echo Reply"<-"All") and port ("8"<-"N/A")
    from_port   = 0
    to_port     = 8
    protocol    = "ICMP"
    description  = "All ICMP - IPv4"
    cidr_blocks = var.my_ip
  }
  egress {
    # All
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
# Create as security group and ingress/egress rules
resource "aws_security_group" "fb_secgrpas" {
    description = "ApplicationServerSecurityGroup"
    name   = "fb_secgrpas"
    vpc_id = aws_vpc.fb_vpc.id
    tags = {
    Name = "fb_secgrpas"
  }
  ingress {
    # SSH
    from_port    = 22
    to_port      = 22
    protocol     = "TCP"
    description  = "SSH"
    security_groups = [aws_security_group.fb_secgrpbh.id]
  }
  ingress {
    # HTTP
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    description  = "HTTP"
    security_groups = [aws_security_group.fb_secgrpbh.id]
  }
  egress {
    # All
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
# Create rds security group and ingress/egress rules
resource "aws_security_group" "fb_secgrprds" {
    description = "RDSSecurityGroup"
    name   = "fb_secgrprds"
    vpc_id = aws_vpc.fb_vpc.id
    tags = {
    Name = "fb_secgrprds"
  }
  ingress {
    # MYSQL/Aurora
    from_port    = 3306
    to_port      = 3306
    protocol     = "TCP"
    description  = "MYSQL/Aurora"
    security_groups = [aws_security_group.fb_secgrpbh.id]
  }
  ingress {
    # MYSQL/Aurora
    from_port    = 3306
    to_port      = 3306
    protocol     = "TCP"
    description  = "MYSQL/Aurora"
    security_groups = [aws_security_group.fb_secgrpas.id]
  }
    egress {
    # All
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "fb_rdssubnetgroup" {
  name       = "fb_rdssubnetgroup"
  subnet_ids = [aws_subnet.fb_privsnrds1.id,aws_subnet.fb_privsnrds2.id]
  tags = {
    Name = "fb_rdssubnetgroup"
  }
 depends_on = [
    aws_subnet.fb_privsnrds1,aws_subnet.fb_privsnrds2
  ]
}
# Create a new AWS windows bastionhost EC2 instance
resource "aws_instance" "fb_bastionhostwindows" {
  ami                         = "ami-0058b78a201737cc0"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.fb_publicsubnet.id
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.fb_secgrpbh.id]  
  tags = {
    Name = "fb_bastionhostwindows"
  }
}
# Create a new as1 linux EC2 instance
resource "aws_instance" "fb_as1" {
  ami                         = "ami-0c0f2d944be57510f"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.fb_privsnas1.id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.fb_secgrpas.id]  
  tags = {
    Name = "fb_as1"
  }
}
# Create a new RDS instance
resource "aws_db_instance" "fb_rdsorangehrm" {
  allocated_storage    = "20"
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0.16"
  instance_class       = "db.t2.small"
  identifier           = "fbrdsorangehrm"
  name                 = "fbrdsorangehrm"
  username             = "admin"
  password             = "welcome01"
  parameter_group_name = "default.mysql8.0"
  option_group_name    = "default:mysql-8-0"
  availability_zone    = var.az1a
  db_subnet_group_name = "fb_rdssubnetgroup"
  vpc_security_group_ids = [aws_security_group.fb_secgrprds.id]
  tags = {
    Name = "fb_rdsorangehrm"
  }
}