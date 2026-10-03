terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.34.0" # Changed from "~> 5.0" to satisfy the ECS module requirement
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  prefix = "group3"
}

resource "aws_ecr_repository" "ecr" {
  name         = "${local.prefix}-ecr"
  force_delete = true
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 7.5.0"

  cluster_name             = "${local.prefix}-ecs"
  cluster_capacity_providers = ["FARGATE"]

  services = {
    "group3-infra" = {
      cpu    = 512
      memory = 1024

      container_definitions = {
        "group3-infra-container" = {
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.prefix}-ecr:latest"
          port_mappings = [
            {
              containerPort = 8080
              protocol      = "tcp"
            }
          ]
        }
      }

      assign_public_ip                   = true
      deployment_minimum_healthy_percent = 100
      subnet_ids                         = ["subnet-04ffbb2f7c7a0d6c9"] # List of subnet IDs to use for your tasks
      security_group_ids                 = ["sg-0a333ad3f5b726f34"] # Create an SG resource and pass it here
    }
  }
}