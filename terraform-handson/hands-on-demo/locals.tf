# ==============================================================================
# LOCAL VALUES (LOCALS)
# ==============================================================================
# Locals are like local variables within a function. They allow you to compute
# expressions once, assign a name, and reuse them throughout your project.
# Unlike Input Variables, they cannot be set externally by the CLI or tfvars files.
# ==============================================================================

locals {
  # Prefix to be used when naming all resources
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags to apply to all resources. We can reference variables or data sources.
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Hands-On-Class"
    # Merges dynamically computed values
    CreatedOn = timestamp() # Note: timestamp() is evaluated on every apply
  }

  # Subnet CIDR calculations (showing Terraform functions in action)
  # cidrsubnet(iprange, newbits, netnum) takes a CIDR and returns a subnet CIDR.
  # "10.0.0.0/16" with 8 additional bits and index 1 -> "10.0.1.0/24"
  subnet_cidr = cidrsubnet(var.vpc_cidr, 8, 1)
}
