# CloudForm Infra

This repository contains the Terraform configuration that provisions the core AWS infrastructure for the **CloudForm** project — a VPC, an EKS cluster, an RDS (MySQL) database, and an ECR repository. It is the second stage of the CloudForm setup, deployed right after [`cloudform-bootstrap`](https://github.com/rajeshdangi409/cloudform-bootstrap) creates the remote state backend.

## 📌 Purpose

`cloudform-infra` builds the entire AWS foundation that the CloudForm application runs on top of:

- A dedicated **VPC** with public and private subnets
- An **EKS cluster** to run the containerized Flask application
- An **RDS MySQL** database, reachable only from inside the cluster
- An **ECR repository** to store the application's Docker images

Once this infra is live, [`cloudform-app`](https://github.com/rajeshdangi409/cloudform-app) builds and pushes images to ECR, and [`cloudform-gitops`](https://github.com/rajeshdangi409/cloudform-gitops) (via FluxCD) deploys them onto this EKS cluster. The apply pipeline in this repo even bootstraps Flux onto the cluster automatically.

## 🏗️ Resources Created

### VPC (`vpc.tf`)
- Name, CIDR, availability zones, and public/private subnet CIDRs all come from variables
- Single NAT Gateway (cost-optimized for dev)
- DNS hostnames and DNS support enabled

### EKS Cluster (`eks.tf`)
- Cluster name and Kubernetes version driven by variables
- Deployed into the VPC's **private subnets**
- Public API endpoint access enabled (for `kubectl` access from outside the VPC)
- Managed node group `general`: instance type from `eks_instance_types`, min 1 / desired 2 / max 2
- Add-ons: `vpc-cni`, `coredns`, `kube-proxy`, `amazon-cloudwatch-observability`
- Cluster creator is automatically granted admin permissions

### RDS Database (`rds.tf`)
- Identifier, engine version, instance class, and database name all driven by variables
- Engine: MySQL, storage: 20 GB auto-scaling up to 1000 GB, encrypted at rest
- **Not publicly accessible** — deployed in private subnets
- A dedicated security group (name from `rds_security_group_name`) only allows inbound MySQL (port `3306`) traffic **from the EKS node security group**, nothing else
- Master password is passed in via the `db_password` variable (sensitive, never hardcoded)

### ECR Repository (`ecr.tf`)
- Repository name driven by `ecr_repository_name` variable
- Mutable image tags
- Image scanning on push enabled

### Remote State Backend (`backend.tf`)
- Empty partial backend block — bucket, key, region, and DynamoDB lock table are all supplied at `terraform init` time via `-backend-config` flags (see CI/CD section), pointing at the resources created by `cloudform-bootstrap`

## 🛠️ Technologies

- Terraform (`>= 1.14.0`)
- AWS Provider (`~> 6.0`)
- Terraform modules: `terraform-aws-modules/vpc`, `terraform-aws-modules/eks`, `terraform-aws-modules/rds`, `terraform-aws-modules/ecr`
- GitHub Actions (CI/CD for Terraform)
- FluxCD (bootstrapped automatically after `apply`)

## 📋 Prerequisites

- `cloudform-bootstrap` must already be applied (S3 + DynamoDB backend must exist)
- AWS CLI configured with appropriate IAM permissions
- Terraform installed locally (for manual runs)
- A GitHub Personal Access Token with repo permissions, for Flux to bootstrap into `cloudform-gitops`

### Required GitHub repository configuration

**Secrets** (Settings → Secrets and variables → Actions → Secrets)
| Name | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `TF_VAR_DB_PASSWORD` | RDS master password |
| `FLUX_GITHUB_TOKEN` | GitHub token used by Flux to bootstrap into the GitOps repo |

**Variables** (Settings → Secrets and variables → Actions → Variables)
| Name | Used for |
|---|---|
| `AWS_REGION` | Provider region + backend config |
| `TF_STATE_BUCKET` | Remote state bucket (from bootstrap) |
| `TF_STATE_KEY` | State file path |
| `TF_LOCK_TABLE` | DynamoDB lock table (from bootstrap) |
| `EKS_CLUSTER_NAME` | Used to update kubeconfig post-apply |
| `FLUX_GITHUB_OWNER` | GitHub owner for Flux bootstrap |
| `FLUX_GITOPS_REPO` | GitOps repo Flux bootstraps into |

## ⚙️ Configuration

All infrastructure inputs are declared in `variables.tf`:

| Variable | Description |
|---|---|
| `aws_region` | AWS region |
| `project_name` / `environment` | Used for consistent resource tagging |
| `vpc_name`, `vpc_cidr`, `availability_zones`, `public_subnet_cidrs`, `private_subnet_cidrs` | VPC/subnet configuration |
| `cluster_name`, `kubernetes_version`, `eks_instance_types` | EKS configuration |
| `rds_identifier`, `rds_engine_version`, `rds_instance_class`, `rds_database_name`, `rds_security_group_name` | RDS configuration |
| `db_password` | RDS master password (sensitive) |
| `ecr_repository_name` | ECR repository name |

For local runs, provide values via a `terraform.tfvars` file (gitignored — never commit it) or `-var` flags, and set the password via environment variable:

```bash
export TF_VAR_db_password="your-secure-password"
```

## 🚀 Deployment — CI/CD Workflows

This repo uses a **two-stage GitHub Actions pipeline** so that infrastructure changes are never applied without review:

### 1. `infra-pipeline.yml` — runs automatically on every push to `main`
Runs `fmt -check`, a backend-configured `init`, `validate`, and `plan` only. This lets you review the plan output on every commit **without ever touching real infrastructure**.

### 2. `terraform-apply.yml` — manual trigger only (`workflow_dispatch`)
Triggered from the **Actions** tab → *Terraform Apply* → *Run workflow*. This is the only workflow that touches real AWS resources, and it does the full end-to-end setup in one run:

1. `terraform init` (with remote backend config), `validate`, `plan`, `apply -auto-approve`
2. Updates local kubeconfig for the new EKS cluster and verifies nodes are ready
3. Installs the Flux CLI
4. Runs `flux check --pre`
5. **Bootstraps Flux** onto the cluster, pointing it at `cloudform-gitops` (`clusters/production` path) — from this point on, Flux takes over deploying application manifests
6. Verifies Flux is healthy and pods are running in `flux-system`

### Manual (local) deployment

```bash
terraform init \
  -backend-config="bucket=<state-bucket>" \
  -backend-config="key=infra/terraform.tfstate" \
  -backend-config="region=<aws-region>" \
  -backend-config="dynamodb_table=<lock-table>"

terraform plan
terraform apply
```

## 🔍 Outputs

| Output | Description |
|---|---|
| `vpc_id` | ID of the created VPC |
| `private_subnet_ids` | List of private subnet IDs (used by EKS and RDS) |
| `public_subnet_ids` | List of public subnet IDs |

```bash
terraform output
```

## 🔗 Usage with Other CloudForm Repositories

```
cloudform-bootstrap
        │  creates S3 + DynamoDB remote backend
        ▼
cloudform-infra   ← this repository
        │  creates VPC, EKS, RDS, ECR
        │  bootstraps Flux onto the cluster
        ▼
cloudform-app      cloudform-gitops
   builds &            watched by Flux;
   pushes image         manifests here get
   to ECR, updates      deployed to EKS
   gitops repo           automatically
```

## 🧹 Cleanup

```bash
terraform destroy
```

> ⚠️ This deletes the VPC, EKS cluster, RDS database, and ECR repository. Make sure Flux-managed workloads are removed or the cluster is otherwise clean first, and note `deletion_protection` is disabled on RDS for easy teardown in dev.

## 📁 Repository Structure

```
cloudform-infra/
│
├── .github/
│   └── workflows/
│       ├── infra-pipeline.yml     # fmt + plan only, runs on push
│       └── terraform-apply.yml    # apply + Flux bootstrap, manual trigger
│
├── backend.tf         # partial S3 backend, configured at init time
├── provider.tf         # AWS provider configuration
├── vpc.tf               # VPC, subnets, NAT gateway
├── eks.tf                 # EKS cluster + managed node group
├── rds.tf                   # RDS MySQL instance + security group
├── ecr.tf                     # ECR repository
├── variables.tf                 # All input variables
├── outputs.tf                     # Output values
├── versions.tf                      # Terraform & provider version constraints
└── .gitignore                         # excludes .terraform/, *.tfstate, *.tfvars
```

## 👨‍💻 Project

**CloudForm** is a DevOps project demonstrating Infrastructure as Code, containerization, Kubernetes, CI/CD, and GitOps using AWS and modern DevOps tools.

Related repositories:
- [`cloudform-bootstrap`](https://github.com/rajeshdangi409/cloudform-bootstrap) — remote state backend
- [`cloudform-app`](https://github.com/rajeshdangi409/cloudform-app) — Flask application + CI pipeline
- [`cloudform-gitops`](https://github.com/rajeshdangi409/cloudform-gitops) — FluxCD GitOps manifests

## 📄 License

This project is licensed under the Apache License 2.0.