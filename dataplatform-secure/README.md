# Dataplatform Secure Example

This is an example of a "simple-ish" data platform consisting of a Data Factory, Storage Account, and an Azure SQL database. All data in rest is encrypted with customer-managed keys and all resources have a private endpoint for private access. Note that networking level (VNETS, NSGs & firewall rules are not part of this terraform)

## Project structure

This project is structured for a complete test/prod separation without any shared components. Environment specific terraform backend definitions and variables are stored in `/dataplatform-secure/config`.

Azure Devops Pipeline definitions are stored in `/dataplatform-secure/pipelines` and they use the correct parameters from `/dataplatform-secure/config`.

## Terraform contents

### DNS

Private DNS records are created only for Data Factory & Azure SQL. For the blob storage correct DNS records need to be created. Also note that in an enterprise setting where this setup usually takes place, DNS forwarding needs to be agreed upon and set up.

### ADF

A

### Identities

Using customer-managed keys forces us in many situations to use user-assigned managed identities for resources. This is required as the resource requires the key on creation, however, a system-assigned managed identity would not have yet rights to read the key. Therefore the resource requires a user-assigned managed identity that has the required read rights to the key.

### Customer-managed keys

CMKs are created in `kv.tf` alongside Key Vaults and KV access policies. They are then referenced in the resources using them.

### SFTP

SFTP is enabled on the landing storage account for integration purposes. As no public access is enabled, it is only reachable via private networks.

### Diagnostic logging

By default, this setup logs quite much directly to Log Analytics. Review them and adjust for your use case.
