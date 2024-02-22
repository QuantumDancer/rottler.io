---
title: "The Cloud Resume Challenge: Infrastructure"
description: "Setting up the development environment"
tags: ["cloud-resume-challenge", "aws", "terraform"]
publishDate: 2024-02-22
---

After creating a simple webpage, I now need to set up infrastructure to host it.
Since I'm currently working on getting my [AWS Certified Solutions Architect - Associate](https://aws.amazon.com/certification/certified-solutions-architect-associate/) certification,
I'm naturally going to use [AWS](https://aws.amazon.com/) to host my webpage.
Of course, the infrastructure should not be created by hand.
This would make it hard to keep the prod and dev environment the same.
Therefore, I will use [Terraform](https://www.terraform.io/) to automatically provision the cloud infrastructure.

In this blog post I describe the general AWS setup and how I set up the development and production environments for the webpage.

For this part, I took some inspiration from these two blog posts:

- https://rtfm.co.ua/en/terraform-remote-state-with-aws-s3-and-state-locking-with-dynamodb/
- https://rtfm.co.ua/en/github-actions-deploying-dev-prod-environments-with-terraform/#Backend

## Setting up the AWS accounts

Because I want to keep the infrastructure of the production and development environment separate, I will create separate AWS accounts for these.
The accounts will be organized via an _AWS Organization_.
I also have a third AWS account that is used as the general management account, so that I don't need to log into the production or development accounts
if I need to apply changes to the AWS Organization.

The structure of the organization looks as follows:

```
└── Root
    ├── aws.rottler.io-general (management account)
    ├── DEV (group)
    │   └── aws.rottler.io-dev
    └── PROD (group)
        └── aws.rottler.io-prod
```

The produdction and development accounts are separated into individual groups.
This allows me to configure permissions for the current and potential future accounts on a role-based level.

Next, I need to set up an IAM user in each of the AWS accounts. 
I will call this user `iamadmin`.
This can be simplified with the help of _IAM Identity Center_, where I just need to configure the user once and then can add the user to all accounts in the organization.
This user will have the `AdministratorAccess` permission set.
With this, I no longer need to log in as the root user of the management account.
Instead, I can use the _AWS access portal_ to login as the `iamadmin` user and then choose in which AWS account I want to log in.
For increased security, I've set up MFA login for both the root user of the general account as well as the `iamadmin` user.
The `iamadmin` user is, as the name suggest, only for administrate purposes, mostly in the beginning when setting things up.
For daily use inside automation pipelines a _IAM Role_ with limited permissions will be used.

## Local setup and tf-admin role

Because I also want access to the `iamadmin` user from my local machine, I need to configure the the AWS CLI.
This can be done with the `aws configure sso` command.
Here, I need to enter the login URL of the AWS access portal that I have set up in the previous session.
I will do this for one account and then duplicate the resulting configuration in `~/.aws/config` for the other accounts:

```ini
[sso-session sso-rottler.io]
sso_start_url = https://<start-id>.awsapps.com/start#
sso_region = us-east-1
sso_registration_scopes = sso:account:access

[profile rottler.io-general]
sso_session = sso-rottler.io
sso_account_id = <general-account-id>
sso_role_name = AdministratorAccess
region = us-east-1
output = json

[profile rottler.io-prod]
sso_session = sso-rottler.io
sso_account_id = <prod-account-id>
sso_role_name = AdministratorAccess
region = us-east-1
output = json

[profile rottler.io-dev]
sso_session = sso-rottler.io
sso_account_id = <dev-account-id>
sso_role_name = AdministratorAccess
region = us-east-1
output = json
```

I can now test if this works by executing a simple command such as 

```bash
aws s3 ls --profile rottler.io-general
```

Here, I make use of the `--profile` option to indicate which profile I want to use.
I can switch between different profiles by specifying the corresponding profile name.

For now, this works. But if I come back later or tomorrow, I will need to reauthenticate again (this was part of the `aws configure sso` step).
I can do this with

```bash
aws sso login --sso-session sso-rottler.io
```

which will trigger an authorization process in the web browser.

Next, I need to set up the IAM role that is going to be used by Terraform.
I haven't figured out yet how to do this via the IAM Identity Center or some other form of automation (because the `iamadmin` account is lacking permissions to add IAM roles), so for now I will do this by hand.
Inside the AWS management console of the production and development account, I've created a role named `tf-admin` with the following permissions policies:

- `AWSCertificateManagerFullAccess`
- `AmazonAPIGatewayAdministrator`
- `AmazonDynamoDBFullAccess`
- `AmazonRoute53FullAccess`
- `AmazonS3FullAccess`
- `CloudFrontFullAccess`

This should get me started to set up the needed infrastructure for the webpage.
Later on, I might refine this list of permissions so that I only have the permissions enabled that I really need.

I also need to set up a _Trust relationship_, so that I can assume this role:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<account-id>:root"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}

```

This trust relationship allows any user from the account to assume this role.

I can now add the following lines to the `~/.aws/config` file so that I have access to the role on my machine:

```ini
[profile rottler.io-prod-tf-admin]
role_arn = arn:aws:iam::<prod-account-id>:role/tf-admin
source_profile = rottler.io-prod

[profile rottler.io-dev-tf-admin]
role_arn = arn:aws:iam::<dev-account-id>:role/tf-admin
source_profile = rottler.io-dev
```

I can test if this worked with the `aws sts get-caller-identity` command:

```bash
aws --profile rottler.io-dev-tf-admin sts get-caller-identity
{
    "UserId": "<UID>:botocore-session-<SessionID>",
    "Account": "<dev-account-id>",
    "Arn": "arn:aws:sts::<dev-account-id>:assumed-role/tf-admin/botocore-session-<SessionID>"
}
```

Nice, now I can get started with setting up the infrastructure for the web page.

## Bootstraping the terraform backend

As mentioned in the introduction, I've decided to use Terraform to provision the AWS infrastructure.
With Terraform, one needs to decide where to store the Terraform _state_.
Terraform provides an [S3 backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3),
where the state can be stored in an _S3 bucket_.
Furthermore, state locking can be achieved with an _DynamoDB table_.

But now I've reached a catch-22 situation:
I want to provision my AWS infrastructure with Terraform, but to run Terraform I need some infrastructure in AWS.
I decided to solve this problem by creating a bootstrap process with [AWS CloudFormation](https://aws.amazon.com/cloudformation/),
the IaC solution provided by AWS.

The following CloudFormation template creates an S3 bucket with a [semi-random name](https://stackoverflow.com/a/68717631) and a DynamoDB table.
I don't want the bucket name to be fully static because each S3 bucket needs to have a globally unique name.

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Resources:
  TerraformStateBucket:
    Type: "AWS::S3::Bucket"
    Properties:
      BucketName:
        !Sub
          - 'rottler-io-tf-state-${RandomGUID}'
          - {
              RandomGUID:
                !Select [
                  0,
                  !Split ["-", !Select [2, !Split ["/", !Ref AWS::StackId]]],
                ],
            }
      VersioningConfiguration: { Status: Enabled }
  TerraformStateLockDBTable:
    Type: 'AWS::DynamoDB::Table'
    Properties:
      TableName: 'rottler-io-tf-state-lock'
      BillingMode: 'PAY_PER_REQUEST'
      AttributeDefinitions:
        - AttributeName: 'LockID'
          AttributeType: 'S'
      KeySchema:
        - AttributeName: 'LockID'
          KeyType: 'HASH'
Outputs:
  TerraformStateBucketName:
    Description: 'The name of the S3 bucket where the Terraform state can be stored.'
    Value: !Ref TerraformStateBucket
  TerraformStateLockDBName:
    Description: The name of the DynamoDB table where the Terraform state lock can be stored.
```

I've put this template and also all following files into the `./infra` folder of my repository.

I can now create a CloudFormation Stack from the template like this:

```bash
export AWS_PROFILE=rottler.io-dev
export AWS_REGION=us-east-1
aws cloudformation create-stack --stack-name terraform-bootstrap --template-body file://bootstrap.yaml
aws cloudformation describe-stacks --stack-name terraform-bootstrap --query "Stacks[0].Outputs[?OutputKey=='TerraformStateBucketName'].OutputValue" --output text
```

The last command gets me the generated bucket name, which I need to set up the Terraform backend.

## Initial configuration for Terraform

Now it's time to set up Terraform. In `main.tf` I only specify the required providers:

```hcl
terraform {
  required_version = "~> 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

First, I need to configure the AWS provider. I'll do this in `providers.tf`.

```hcl
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      created-by  = "terraform"
      environment = var.environment
    }
  }
}
```

I've configured the `environment` variable in `variables.tf`:
```hcl
variable "environment" {
  description = "dev/prod environment"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Invalid environment. Allowed values: dev, prod."
  }
}
```
It can be set via the `TF_VAR_environment` environment variable.

For the backend configuration, I break things up into `backend.tf` for configuration that is common between the development and production environment
and `backend.dev.hcl`, where I store settings specific for the development environment.
Later I'll also add a `backend.prod.hcl` config for the production environment.
I specify the backend configuration.

The `backend.tf` file looks like this:

```hcl
terraform {
  backend "s3" {
    key = "terraform.tfstate"
  }
}
```

While `backend.dev.hcl` has this content:
```hcl
bucket         = "rottler-io-tf-state-<bucket-id>"
region         = "us-east-1"
dynamodb_table = "rottler-io-tf-state-lock"
encrypt        = true
```

I can now initialize Terraform with

```bash
export AWS_PROFILE=rottler.io-dev
export AWS_REGION=us-east-1
export TF_VAR_role_arn=arn:aws:iam::<dev-account-id>:role/tf-admin
export TF_VAR_environment=dev
terraform init -backend-config=backend.dev.hcl
```

## More variables

Because it's good practice to not hardcode names or "magic values" I define a few more variables in `variables.tf`:

```hcl
variable "project_name" {
  description = "A project name to be used in resources"
  type        = string
  default     = "rottler-io"
}

variable "top_level_domain" {
  description = "The top level domain for the website"
  type        = string
  default     = "rottler.io"
}

locals {
  domain_name = "${var.environment}.${var.top_level_domain}"
  cloudfront_aliases = var.environment == "prod" ? [var.top_level_domain, "www.${var.top_level_domain}", "${var.environment}.${var.top_level_domain}"] : ["${var.environment}.${var.top_level_domain}"]
}
```

- I will use `var.project_name` in resource names to make clear that this resource is used for this project.
- `var.top_level_domain` specifies the TLD for the website.
- `local.domain_name` will become either `dev.rottler.io` or `prod.rottler.io` depending on the environment.
- `local.cloudfront_aliases` is a list of aliases for the CloudFront distribution. This is slightly more complex than the other variables, but I want the production version of the webpage to be reachable via [rottler.io](https://rottler.io), [www.rottler.io](https://www.rottler.io), and [prod.rottler.io](https://prod.rottler.io).

## S3 and Cloudfront

For the webpage I first need an S3 bucket where I can store the content.
I've decided that I will separate my Terraform code between different AWS services, so I will put this code into `s3.tf`.

```hcl
resource "random_id" "website_bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "website" {
  bucket = "${local.domain_name}-${random_id.website_bucket_id.hex}"
  tags = {
    Name = "${local.domain_name}-${random_id.website_bucket_id.hex}"
  }
}

```

Next, I need to set up a _CloudFront distribution_ that serves the webpage in the S3 bucket. This is going into `cloudfront.tf`

```hcl
locals {
  cf_website_s3_origin_id = "S3-${aws_s3_bucket.website.id}"
}

resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    origin_id                = local.cf_website_s3_origin_id
  }

  enabled         = true
  is_ipv6_enabled = true

  comment             = "S3 bucket for ${local.domain_name}"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "cloudfront/${local.domain_name}/"
  }

  aliases = local.cloudfront_aliases

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.cf_website_s3_origin_id
    cache_policy_id        = aws_cloudfront_cache_policy.website.id
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

}

resource "aws_cloudfront_cache_policy" "website" {
  name        = "website-policy"
  comment     = "Cache policy for ${local.domain_name}"
  default_ttl = 86400
  min_ttl     = 0
  max_ttl     = 31536000
  parameters_in_cache_key_and_forwarded_to_origin {
    headers_config {
      header_behavior = "none"
    }
    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "S3Website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
```

This is quite a lot of code, so I only will give an overview what it does:

- The S3 bucket from above will be used as the origin of the CloudFront distribution.
- Logs will be written into a second S3 bucket.
- All alternative domain names that are defined in `local.cloudfront_aliases` are set.
- The default cache behavior is defined, defining the HTTP methods that are allowed and the ones that get cached and the CDN locations.
  Furthermore, HTTP traffic is set up to redirect to HTTPS.
- Because I only need to support traffic from Europe, I can set the price class `PriceClass_100`, which covers North America and Europe.

## Setting up the custom domains

Per default, the CloudFront distribution is available at a `*.cloudfront.net` address.
I've used the `alias` option the definition of the CloudFront distribution to also enable support
for my own domain.
However, routing does not yet work, because I first need to create the DNS entries.

As a reminder, I'm working with a setup based on three acounts: The general account (mostly for management), the dev account, and the prod account.
The domain `rottler.io` is managed in the general account.
Here, I have created a _Hosted Zone_ that handles general DNS records, for example everything needed to get email to work with my custom domain.

I can create a Hosted Zone in the dev and prod account with Terraform.

```hcl
resource "aws_route53_zone" "website" {
  name = local.domain_name
}
```

This Hosted Zone will have four name servers assigned to by AWS.
I need to connect this Hosted Zone to the one in the general account by creating a `NS` entry in the general account
(using either `dev.rottler.io` or `prod.rottler.io` as the name), that points to these four name servers.

Next, I need to create an `A` record to point to the CloudFront distribution.
Because there is not only a simple server behind a CloudFront distribution but a mesh of CDN locations,
a special _Alias Record_ needs to be used.

```hcl
resource "aws_route53_record" "website" {
  zone_id = aws_route53_zone.website.zone_id
  name    = local.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = true
  }
}
```

## Enabling SSL support for the custom domain

Next, I need to set up a SSL certificate, because I've set up the CloudFront distribution to only work via HTTPS.
This can be done with the AWS Certificate Manager:

```hcl
resource "aws_acm_certificate" "website_cert" {
  domain_name = var.environment == "prod" ? var.top_level_domain : local.domain_name
  subject_alternative_names = var.environment == "prod" ? ["www.${var.top_level_domain}", local.domain_name] : []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

```

Here again, I need to differentiate between the produdction and development environment.
For dev, I just need a certificate for `dev.rottler.io`, while for prod I need the domain name to be `rottler.io`,
and also add support for the two other domains, `www.rottler.io` and `prod.rottler.io`.

Unfortunately, the validation of the SSL certificate can only be automated for the dev account.

```hcl
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.website_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.website.zone_id
}

```

This does not work for the prod account, because the Hosted Zone in the prod account only works for `prod.rottler.io`,
but not for `rottler.io` or `www.rottler.io`.
Those two other domain names can only be managed from the Hosted Zone in the general account.
Furthermore, the ACM certificate needs to live in the same account as the CloudFront distribution.
This is a limitation of my current setup, I might want to revisit this in the future.
For now, I've just manually copied the verification DNS records from the prod account to the general account.

With this, the SSL certificates are validated and can now be attached to the CloudFront distribution.

```hcl
resource "aws_cloudfront_distribution" "website" {
  // ...

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.website_cert.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  // ...

}

```

## Testing the wegpage

In order to test the infrastructure that I've set up above I first need to put some files into the S3 bucket.
I can locally build a production version of the webpage and push it to the S3 bucket:

```bash
cd ../webpage
npx astro build
aws s3 cp ./dist/ s3://dev.rottler.io-<bucket-id>/ --recursive
```

I can now navigate to [dev.rottler.io](https://dev.rottler.io).
The main page shows up, so that's great.
However, navigating to any other page fails with an `AccessDeniedAccess` error from CloudFront.
Why is this the case?

## Fixing routing for subpages

When going to a subpage, e.g. [dev.rottler.io/blog/](https://dev.rottler.io/blog/), the `index.html`
document that is located in this folder should be served.
This is done automatically when running the webpage locally with `npm run dev`, but for CloudFront I need
to put in some additional work.

The solution is to add [a simple Lambda function](https://stackoverflow.com/a/76581267)
that appends `index.html` to each request when it is not present.

```hcl
resource "aws_cloudfront_function" "append_index_html" {
  name    = "append_index_html"
  runtime = "cloudfront-js-2.0"
  comment = "Append index.html when it's missing from the URL"
  code    = file("${path.module}/scripts/cloudfront_append_index_html.js")
}

resource "aws_cloudfront_distribution" "website" {
  // ...

  default_cache_behavior {
    // ...

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.append_index_html.arn
    }
  }

  // ...
```

After a final `terraform apply` everything is working now and I have a functioning web site.

Next, I'm going to work on the automatic provisioning of infrastructure changes and automatic deployments of new content.
