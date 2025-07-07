@echo off
echo ========================================
echo  GenAI Healthcare POC - Complete Deploy
echo ========================================
echo.

echo Step 1: Installing Lambda dependencies...
cd ..\lambda
pip install -r requirements.txt -t .
cd ..\terraform

echo.
echo Step 2: Initializing Terraform...
terraform init

echo.
echo Step 3: Planning deployment...
terraform plan -out=tfplan

echo.
echo Step 4: Applying complete infrastructure...
terraform apply tfplan

echo.
echo Step 5: Getting deployment outputs...
terraform output

echo.
echo ========================================
echo  Deployment Complete!
echo ========================================
echo.
echo Frontend URL: 
terraform output frontend_url
echo.
echo API Endpoints:
terraform output api_endpoint
echo.
echo Note: Frontend deployment takes 5-10 minutes to complete.
echo Check the site in a few minutes at the Frontend URL above.
echo.
pause