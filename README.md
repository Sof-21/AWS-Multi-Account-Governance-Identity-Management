# AWS-Multi-Account-Governance-Identity-Management
This project is a learning demo on how to configure aws organization and identity management at scale 
Test



Note: unfortunately terraform, aws cli/sdk both does not provide an automated/script way to initialize identity center inside the organization. the only available command would be `create-instance`, but, it will initiialize identity center as a standalone product  that is not managed by organizations or member aws account in the organization. In this case, the only option was to use the aws console to initialize identity center in us-east-1 region, or any region of your choice.


### Tech Stack
<p>
  <img src="https://skillicons.dev/icons?i=terraform,aws,git,github" />
</p>