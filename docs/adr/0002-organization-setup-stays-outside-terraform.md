# Organization setup stays outside Terraform

Changes at the AWS Organizations level, such as creating member accounts, placing them in OUs, and assigning IAM Identity Center access, are one-off CLI calls run from the management account. They are recorded in the change that made them, not managed by a Terraform root. Terraform state has to live somewhere: the management account is meant to stay resource-free, and a member account such as shared-services cannot hold the state that created it. The organization changes rarely, so a root that exists only to hold a few accounts and assignments would cost more than it saves. Organization metadata itself (memberships, OU placement, Identity Center assignments) does not count as a resource in the management account.

## Considered Options

- **A Terraform root with state in the management account**: rejected. It breaks the resource-free management account for a handful of rarely changing objects.
- **A Terraform root with state in the shared-services account**: rejected. It is circular: the account would hold the state of its own creation, and a broken state bucket there would lock out management of the whole organization.

## Consequences

- Revisit this decision if organization changes become frequent, for example once service control policies are introduced. A delegated administrator account could then hold the state without touching the management account.
