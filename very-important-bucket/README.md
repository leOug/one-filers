A Very Important Bucket
---

***Warning*** DO NOT use this bucket to store sensitive data as is.

Everyone needs a bucket for important configs. The bucket is created with versioning in order to
retain the history of the config files and also it is private.

The bucket is created using a random UUID in is name in order to avoid accidental requests
if the name somehow matches someone else's bucket.

In a normal terraform scenario this file would look something like this:

```text

very-important-bucket/
├── main.tf                  # Root module to tie everything together
├── variables.tf             # All variable declarations
├── outputs.tf               # Output values for external use
├── providers.tf             # Provider and Terraform settings
├── README.md                # Documentation for the module
├── modules/
│   └── s3_bucket/
│       ├── main.tf          # Bucket, versioning, ACL, ownership controls
│       ├── variables.tf     # Module-specific variables like bucket name, prefixes
│       ├── outputs.tf       # Outputs (bucket name, arn, etc.)
└── terraform.tfvars         # Optional: values for variables

```

```bash
terraform init
```
```bash
terraform plan -out very-important-bucket.tfplan
```
```bash
terraform apply
```