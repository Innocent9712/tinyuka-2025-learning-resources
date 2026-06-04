# ==============================================================================
# PROVIDERS CONFIGURATION
# ==============================================================================
# In Terraform, providers are plugins that interact with cloud providers, SaaS
# providers, and other APIs. This file declares the versions and configurations
# for the providers our project requires.
# ==============================================================================

terraform {
  # Pins the minimum Terraform CLI version required to run this code.
  # We require >= 1.10.0 because of S3 native state locking (use_lockfile = true).
  required_version = ">= 1.10.0"

  # Declares which provider plugins are required and where to download them.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Allows minor version upgrades (e.g. 5.x) but not major ones.
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0" # Used to generate random resource names or tags.
    }
  }
}

# The provider block configures the specified provider (AWS).
# You can define credentials and regions here, or let Terraform load them
# automatically from environment variables or standard AWS CLI configuration.
provider "aws" {
  region = var.aws_region

  # Default tags are automatically applied to all AWS resources created by this provider.
  # This is a best practice to enforce consistent tagging.
  default_tags {
    tags = local.common_tags
  }
}
