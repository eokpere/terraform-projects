terraform {
  required_version = "~> 1.0" # which means any version equal & above 0.14 like 0.15, 0.16 etc and < 1.xx
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

 # Provider Block
provider "aws" {
   region  = "ca-central-1"
 }


resource "aws_s3_bucket" "eva-buc-terraform" {
  bucket = "eva-buc-terraform"
}

resource "aws_s3_bucket_acl" "eva-buc-terraform" {
  bucket = aws_s3_bucket.eva-buc-terraform.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_eva-buc-terraform" {
  bucket = aws_s3_bucket.eva-buc-terraform.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name = "terraform-lock"
  hash_key = "LockID"
  read_capacity = 3
  write_capacity = 3
  attribute {
     name = "LockID"
     type = "S"
   }
  tags = {
    Name = "Terraform Lock Table"
   }
   lifecycle {
   prevent_destroy = false
  }
 }
