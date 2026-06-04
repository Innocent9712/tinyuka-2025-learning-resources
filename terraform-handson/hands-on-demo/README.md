# Terraform Hands-On Demo Guide

Welcome to the Terraform Hands-On Demo! This directory contains a fully functional, simple AWS deployment that you can use to explain and demonstrate the core concepts of Terraform and Infrastructure as Code (IaC).

It has been structured to walk you (or your team) through concepts step-by-step by commenting sections in/out and showing CLI outcomes.

---

## Prerequisites
1. **Terraform CLI**: v1.10.0 or later (required for S3 native locking). You currently have `v1.15.5` installed!
2. **AWS CLI**: Configured with valid administrator credentials:
   ```bash
   aws configure
   ```

---

## Lesson Plan & Show-and-Tell Steps

### Step 1: Providers, Variables, & Local State
By default, the S3 backend configuration in `backend.tf` is commented out. This means Terraform will use **Local State**.

1. **Explain Project Structure**:
   - `providers.tf`: Pluggable nature of Terraform, versions, and configuring provider blocks (e.g. AWS).
   - `variables.tf`: Input variables, default values, and the `validation` rule constraining `instance_type`.
   - `locals.tf`: Computed private variables vs input variables (showcasing functions like `cidrsubnet()`).
   - `datasources.tf`: Querying external APIs (getting the latest Ubuntu AMI and active AZs).
   - `main.tf`: Declaring actual physical resources. Currently, only **Section 1: Networking** is uncommented.

2. **Initialize Terraform**:
   - Run `terraform init` to download provider plugins. Show how Terraform creates the `.terraform/` folder and the `.terraform.lock.hcl` lock file.
   ```bash
   terraform init
   ```

3. **Format & Validate**:
   - Run `terraform fmt` to enforce HCL code style guidelines.
   - Run `terraform validate` to check syntax and structure without invoking AWS APIs.
   ```bash
   terraform fmt
   ```
   ```bash
   terraform validate
   ```

4. **Review the Dry-Run Plan**:
   - Run `terraform plan`. Point out the symbols:
     - `+` means a resource will be created.
     - Note that attributes like `id` and `arn` are `(known after apply)` because AWS assigns them during creation.
   ```bash
   terraform plan
   ```

5. **Deploy the Networking Stack**:
   - Run `terraform apply`. Look at the prompt, type `yes` to confirm.
   ```bash
   terraform apply
   ```

6. **Inspect Local State**:
   - Once complete, point out that a `terraform.tfstate` file has appeared in this folder.
   - Open the JSON file to show how Terraform maps your configuration to real-world resources (e.g., AWS VPC ID).
   - Run state commands to query it without opening the file:
     ```bash
     terraform state list
     terraform state show aws_vpc.main
     ```

---

### Step 2: Show-and-Tell State Migration (Local to Remote S3)
To move from local state to remote state using the new **S3 Native Locking** (which does not require a DynamoDB table), we first need to bootstrap our S3 bucket.

#### 1. Create the S3 Bucket Outside Terraform (AWS CLI)
Run the following commands in your shell to create and secure your S3 bucket. Replace `YOUR-UNIQUE-BUCKET-NAME` with a unique bucket name (e.g., `my-tf-state-12345`).

**Create Bucket (for us-east-1)**:
```bash
aws s3api create-bucket \
  --bucket YOUR-UNIQUE-BUCKET-NAME \
  --region us-east-1
```
*(If using a region other than `us-east-1`, add `--create-bucket-configuration LocationConstraint=your-region`)*

**Enable Bucket Versioning (Required for S3 Locking)**:
```bash
aws s3api put-bucket-versioning \
  --bucket YOUR-UNIQUE-BUCKET-NAME \
  --versioning-configuration Status=Enabled
```

**Enable Server-Side Encryption (Best Practice)**:
```bash
aws s3api put-bucket-encryption \
  --bucket YOUR-UNIQUE-BUCKET-NAME \
  --server-side-encryption-configuration '{
    "Rules": [
      {"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}
    ]
  }'
```

**Block Public Access (Critical Security Best Practice)**:
```bash
aws s3api put-public-access-block \
  --bucket YOUR-UNIQUE-BUCKET-NAME \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

#### 2. Migrate the State File
1. Open `backend.tf` and **uncomment** the `terraform` block.
2. Replace `bucket = "your-unique-terraform-state-bucket"` with the name of the S3 bucket you just created.
3. Run `terraform init`:
   ```bash
   terraform init
   ```
4. Terraform will detect that you have existing local state and ask if you want to copy it to S3:
   ```
   Do you want to copy existing state to the new backend?
     Pre-existing state was found while migrating the previous "local" backend to the 
     newly configured "s3" backend. No existing state was found in the "s3" backend.
     Do you want to copy this state to the new "s3" backend? Enter "yes" to copy and "no"
     to start with an empty state.
   ```
5. Type `yes`.
6. Inspect your directory. The local `terraform.tfstate` is now empty or renamed to `terraform.tfstate.backup`. Your real state file is securely locked in S3.
7. Run `terraform plan` to verify that everything is in sync and no changes are needed.

---

### Step 3: Add Security Groups & Compute (Iterative Development)
Now let's show how Terraform handles adding new resources and managing dependencies between them.

1. **Uncomment Section 2 (Security Group)** in `main.tf`.
2. Run `terraform plan`. Show how Terraform detects that exactly `1 resource will be created` (the Security Group) and the VPC/Subnet will not be touched.
3. **Uncomment Section 3 (Compute)** in `main.tf`.
4. **Uncomment the EC2 outputs** in `outputs.tf` (lines 20-33).
5. Run `terraform plan`. Explain how Terraform calculates the dependency tree:
   - The EC2 instance (`aws_instance.web`) depends on the Security Group (`aws_security_group.web`) and Subnet (`aws_subnet.main`).
   - Terraform handles these dependencies automatically!
6. Run `terraform apply` to deploy the web server.
   ```bash
   terraform apply
   ```
7. Visit the output URL in your browser to see your styled web server page!

---

### Step 4: Update-In-Place vs Re-Creation
Show how changing different arguments affects resources differently.

1. **Update-in-Place (Tag Change)**:
   - Change `environment = "dev"` to `environment = "staging"` in `terraform.tfvars`.
   - Run `terraform plan`. Note the `~` symbol indicating update-in-place. Terraform only modifies tags without destroying anything.
2. **Re-Creation (Force Replacement)**:
   - Change `vpc_cidr = "10.0.0.0/16"` to `vpc_cidr = "10.1.0.0/16"` in `terraform.tfvars`.
   - Run `terraform plan`. Look at the `- / +` symbol. Because VPC CIDR blocks cannot be modified on the fly in AWS, Terraform must destroy the VPC and rebuild it (along with all dependent subnets and EC2 instances).
   - *Discard this change before applying so you don't destroy your web server.*

---

### Step 5: Modularize (Local & Remote Modules)
Show how to reuse configuration by invoking a custom local module and a remote public registry module.

1. **Uncomment Section 4 (Modules)** in `main.tf`.
2. **Uncomment Section 4 Outputs** in `outputs.tf` (lines 45-57).
3. **Run `terraform plan` immediately**: Note that it fails!
   - Explain that because you introduced a new remote registry module, Terraform must first download the module files to the `.terraform/modules` directory.
4. **Re-initialize to install modules**:
   ```bash
   terraform init
   ```
   Show the output indicating that it downloads `terraform-aws-modules/security-group/aws` from the HashiCorp registry.
5. **Run `terraform plan`**:
   - Point out that it will create the local module S3 bucket and the remote module security group.
   - Explain how variables are passed into modules (e.g. `bucket_name`) and how outputs are accessed from modules (e.g. `module.custom_s3_bucket.bucket_id`).
6. **Apply the changes**:
   ```bash
   terraform apply
   ```

---

### Step 6: Destruction
Show how easy it is to clean up everything when finished.

1. Run `terraform destroy`:
   ```bash
   terraform destroy
   ```
2. Type `yes` to confirm. Look at AWS to see all resources (including those created by the modules) being cleanly deleted.
3. Clean up the S3 state bucket manually from the AWS CLI:
   ```bash
   # Delete the state file first
   aws s3 rm s3://YOUR-UNIQUE-BUCKET-NAME/hands-on-demo/terraform.tfstate
   # Delete the bucket
   aws s3api delete-bucket --bucket YOUR-UNIQUE-BUCKET-NAME --region us-east-1
   ```

