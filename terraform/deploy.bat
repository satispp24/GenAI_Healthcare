@echo off
echo Installing Lambda dependencies...
cd ..\lambda
pip install -r requirements.txt -t .
cd ..\terraform
echo Running Terraform...
terraform init
terraform plan
terraform apply