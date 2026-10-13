terraform {
  required_version = "~> 1.16.0"

  backend "s3" {
    bucket       = "maor-terraform-state-533267148415-eu-north-1"
    key          = "devops-dashboard/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "IPv4 CIDR allowed to connect over SSH"
  type        = string
}

resource "aws_security_group" "web" {
  name        = "terraform-web-sg"
  description = "Security group for the Terraform EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name = "terraform-web-sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP from anywhere"
}
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}
output "web_security_group_id" {
  description = "ID of the Terraform web security group"
  value       = aws_security_group.web.id
}

data "aws_subnet" "target" {
  vpc_id            = var.vpc_id
  availability_zone = "eu-north-1b"
}

output "target_subnet_id" {
  value = data.aws_subnet.target.id
}








resource "aws_iam_role" "ec2" {
  name = "terraform-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ec2" {
  name = "terraform-ec2-instance-profile"
  role = aws_iam_role.ec2.name
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "aws_ami_id" {
  value = data.aws_ami.ubuntu.id
}
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.target.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true


  credit_specification {
    cpu_credits = "standard"
  }
  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name = "terraform-web-server"
  }
}



output "web_instance_id" {
  value = aws_instance.web.id
}




resource "aws_s3_bucket" "practice" {
  bucket = "maor-devops-practice-533267148415-eu-north-1"

  tags = {
    Name = "terraform-s3-practice"
  }
}
resource "aws_s3_bucket_public_access_block" "practice" {
  bucket = aws_s3_bucket.practice.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "practice" {
  bucket = aws_s3_bucket.practice.id
  key    = "practice.txt"
  source = "${path.module}/practice.txt"
}
resource "aws_iam_role_policy" "s3_read_practice" {
  name = "terraform-ec2-s3-read-practice"
  role = aws_iam_role.ec2.name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Sid      = "ReadPracticeObject"
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = aws_s3_object.practice.arn
    }]
  })
}

resource "aws_s3_object" "imported_practice" {
  bucket = aws_s3_bucket.practice.id
  key    = "import-practice.txt"
}

resource "aws_key_pair" "maor" {
  key_name   = "maor-terraform-key"
  public_key = file(pathexpand("~/.ssh/maor-terraform.pub"))
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = var.ssh_allowed_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH from my IP"
}


module "practice_object" {
  source = "./modules/practice_object"

  bucket_name    = aws_s3_bucket.practice.id
  object_key     = "module-practice.txt"
  object_content = "Created by a reusable Terraform module"
}

output "module_object_key" {
  description = "Key returned by the practice object module"
  value       = module.practice_object.object_key
}