# AWS-Multi-Account-Governance-Identity-Management
This project is a learning demo on how to configure aws organization and identity management at scale 
Test


### What terraform cant do?
#### initialize/enable identity center 
Note: unfortunately terraform, aws cli/sdk both does not provide an automated/script way to initialize identity center inside the organization. the only available command would be `create-instance`, but, it will initiialize identity center as a standalone product  that is not managed by organizations or member aws account in the organization. In this case, the only option was to use the aws console to initialize identity center in us-east-1 region, or any region of your choice.

#### identity center setting management
Terraform currently does not manage the highlevel settings and access portal url. incase you prefer a custom start url then you would need to do it manually from the identity center settings page.

### Tech Stack
<p>
  <img src="https://skillicons.dev/icons?i=terraform,aws,git,github" />
</p>



## Design choices
### multiple use of resource "aws_ssoadmin_account_assignment"
In my Permission_set.tf file i used the above tf command to assign permission sets to respective aws accounts. i used to repeat the above command over using `for_each` loop, my reason is its simpler, in my case i only have two accounts dev and prod, so this approach was suitable for me. in cases where there are a lot more of aws account needing to be assigned with permission sets, then usage of `for_each` would be the best option.