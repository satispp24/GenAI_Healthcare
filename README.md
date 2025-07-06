# 🧠 GenAI Healthcare POC

An end-to-end Generative AI application for clinical workflows. This solution enables medical professionals to upload audio files, transcribe them using Amazon Transcribe Medical, and generate SOAP notes using Amazon Bedrock (e.g., Claude).

---

## 🔧 Technologies Used

- **Frontend**: React (JavaScript)
- **Backend**: AWS Lambda (Python)
- **Infrastructure**: Terraform (IaC)
- **AI Services**:
  - Amazon Transcribe Medical
  - Amazon Bedrock (Claude, Titan, etc.)
- **Storage**: Amazon S3
- **Security**: Pre-signed URLs

---

## 🚀 Setup Instructions

### 1. Clone the Repo
```bash
git clone https://github.com/satispp24/GenAI_Healthcare_POC.git
cd GENAI_Clinical
```

### 2. Infrastructure (Terraform)
```bash
cd terraform
terraform init
terraform apply
```

Update `variables.tf` with:
- Bucket name
- Region
- Lambda ARNs (if pre-deployed)

### 3. Lambda Deployment
```bash
cd lambda
pip install -r requirements.txt -t .
zip -r lambda.zip .
# Upload this zip to your Lambda functions via AWS Console or Terraform
```

### 4. Frontend Setup
```bash
cd frontend
npm install
npm start
```
## 5. Bedrock Setup

To enable SOAP note generation using Amazon Bedrock and Claude models:

### 1. **Enable Bedrock Access**
- Go to the [Amazon Bedrock Console](https://console.aws.amazon.com/bedrock/)
- Ensure Bedrock is enabled in your AWS account and region (e.g., `us-east-1`)
- Request access to **Claude (Anthropic)** models if not already granted

### 2. **Assign IAM Permissions**
Make sure the Lambda role has the correct permissions:
```json
{
  "Effect": "Allow",
  "Action": [
    "bedrock:InvokeModel",
    "bedrock:InvokeModelWithResponseStream"
  ],
  "Resource": "*"
}
```

> Tip: Restrict the `"Resource"` field to a specific model ARN for tighter security, e.g.:
> `"arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1"`

### 3. **Model ID Configuration**
The model used is:
```
anthropic.claude-3-sonnet-20240229-v1:0
```
If using a different Claude version, update the `modelId` in `generate_note.py` accordingly.

### 4. **Region**
This app defaults to `us-east-1`. Modify `generate_note.py` if you want to change regions:
```python
bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
```

---

## 🌐 API Endpoints

| Endpoint          | Description                          |
|------------------|--------------------------------------|
| `/presign`       | Generate secure upload URL           |
| `/invoke`        | Trigger transcription and GenAI flow |

---

## ✍️ Example Prompt to Claude (Bedrock)

```text
Please convert the following transcript into a SOAP note format suitable for electronic health records.
```

---

## 🛡️ Security

- Pre-signed S3 URLs ensure secure and temporary uploads.
- You can integrate with Amazon Cognito for user authentication (TODO).

---

## 📌 To Do

- [ ] Add Cognito authentication
- [ ] Implement retry logic in Lambda
- [ ] Add CI/CD via GitHub Actions
- [ ] Improve error handling and logging
- [ ] HIPAA compliance audit

---

## 🧑‍💻 Contributors

Satish Patil
Sr Solution Architect

---

## 📬 Contact

For enterprise use or support, contact your AWS Account Manager or Solutions Architect.

---

## 📄 License

MIT License — free to use and modify.
