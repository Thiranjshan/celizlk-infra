\# CelizLK — Infrastructure as Code



Terraform configuration for the CelizLK e-commerce platform's Azure infrastructure:

a Linux VM running the containerized Next.js app behind Caddy, and a managed

PostgreSQL Flexible Server.



This is the companion infrastructure repo to \[`celizlk`](https://github.com/Thiranjshan/CelizLK),

which holds the application code and CI/CD pipeline.



\## Architecture



\- \*\*Resource group\*\* — `celiz\_group`

\- \*\*Compute\*\* — `Standard\_B2ats\_v2` Linux VM (Ubuntu 22.04 LTS), running the app

&#x20; and Caddy as Docker containers

\- \*\*Networking\*\* — a virtual network, subnet, static public IP, and an NSG

&#x20; allowing inbound 80/443 (public) and 22 (SSH)

\- \*\*Database\*\* — Azure Database for PostgreSQL Flexible Server

&#x20; (Burstable, `B1ms`), with firewall rules scoped to the VM and admin IP

\- \*\*Monitoring\*\* — Azure Monitor agent and a default action group on the VM



\## Why this repo exists



The infrastructure was originally provisioned manually through the Azure

portal to validate the deployment approach quickly. Once the app was stable

in production, every resource was brought under Terraform management with

`terraform import`, rather than destroying and recreating live infrastructure.

`terraform plan` against this configuration returns no changes, confirming the

code accurately reflects what's running.



This mirrors a common real-world scenario: adopting Infrastructure as Code

for infrastructure that already exists and is serving traffic, without downtime

or data loss.



\## Prerequisites



\- \[Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5

\- \[Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), authenticated via `az login`

\- An `azurerm` provider-compatible Azure subscription with access to the `celiz\_group` resource group



\## Usage



```bash

terraform init

terraform plan

```



`terraform plan` should report \*\*no changes\*\* against the live environment.

Any diff means the configuration and the real infrastructure have drifted

apart and should be reconciled before applying.



To apply a genuine, intended change:



```bash

terraform apply

```



\## Secrets



The PostgreSQL administrator password is supplied via `pg\_admin\_password`

in a local `celiz.auto.tfvars` file, which is \*\*not committed\*\* (see

`.gitignore`). To run this yourself, create that file locally:



```hcl

pg\_admin\_password = "your-database-password"

```



\## State



Terraform state is currently stored locally and is not committed to version

control. Migrating to a remote backend (Azure Storage) is a planned next step.



\## Roadmap



\- \[ ] Remote state backend (Azure Storage)

\- \[ ] Import the backup storage account

\- \[ ] Separate `dev`/`prod` workspaces or environments

\- \[ ] CI pipeline running `terraform plan` on pull requests

