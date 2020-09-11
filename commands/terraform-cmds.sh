terraform init
terraform plan
terraform validate && terraform fmt
terraform apply
terraform show
terraform state list
terraform apply -var="region=us-east-1"
terraform apply \
  -var-file="secret.tfvars" \
  -var-file="production.tfvars"
