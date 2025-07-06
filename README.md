# 🧠 GenAI Healthcare POC - Complete Documentation

## Overview
End-to-end Generative AI application for clinical workflows that enables medical professionals to upload audio files, transcribe them using Amazon Transcribe Medical, and generate SOAP notes using Amazon Bedrock (Claude 3).

---

## 🏗️ Architecture

### System Components
- **Frontend**: React.js application
- **API Layer**: AWS API Gateway (HTTP API)
- **Compute**: AWS Lambda functions
- **Storage**: Amazon S3
- **AI Services**: Amazon Transcribe Medical + Amazon Bedrock
- **Infrastructure**: Terraform (IaC)

### Data Flow
1. User uploads audio → React App
2. App requests presigned URL → API Gateway → Lambda
3. App uploads audio to S3 using presigned URL
4. App triggers processing → API Gateway → Lambda
5. Lambda starts Transcribe Medical job
6. Transcribe processes audio from S3
7. Lambda retrieves transcript
8. Lambda sends transcript to Bedrock (Claude)
9. Bedrock generates SOAP note
10. Lambda saves SOAP note to S3
11. Lambda returns transcript + SOAP note to App

---

## 📋 Prerequisites

### AWS Account Setup
- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform installed (v1.0+)
- Node.js (v16+) and npm
- Python 3.11+

### Required AWS Services Access
- Amazon S3
- AWS Lambda
- Amazon API Gateway
- Amazon Transcribe Medical
- Amazon Bedrock (Claude 3 access)
- AWS IAM

---

## 🚀 Deployment Guide

### Step 1: Clone Repository
```bash
git clone https://github.com/satispp24/GenAI_Healthcare_POC.git
cd GenAI_Healthcare_POC
```

### Step 2: Configure AWS Credentials
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region (us-east-1), and output format
```

### Step 3: Enable Amazon Bedrock Access
1. Go to [Amazon Bedrock Console](https://console.aws.amazon.com/bedrock/)
2. Navigate to "Model access" in the left sidebar
3. Click "Request model access"
4. Select "Anthropic Claude 3 Sonnet" model
5. Submit request and wait for approval (usually instant)

### Step 4: Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Note the outputs:**
- `api_endpoint`: Your API Gateway URL
- `upload_bucket_name`: S3 bucket name

### Step 5: Deploy Lambda Functions
```bash
cd ../lambda
pip install -r requirements.txt -t .
cd ../terraform
terraform apply  # Re-apply to update Lambda with dependencies
```

### Step 6: Configure Frontend
```bash
cd ../frontend
cp .env.example .env
# Edit .env and set REACT_APP_API_ENDPOINT to your API Gateway URL
npm install
npm start
```

---

## 📁 Project Structure

```
GenAI_Healthcare_POC/
├── terraform/
│   ├── main.tf              # Main infrastructure
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   └── deploy.bat          # Deployment script
├── lambda/
│   ├── handler.py          # Main processing Lambda
│   ├── presign_url.py      # URL generation Lambda
│   ├── generate_note.py    # SOAP note generation
│   └── requirements.txt    # Python dependencies
├── frontend/
│   ├── src/
│   │   ├── App.js          # Main React component
│   │   ├── UploadForm.js   # File upload component
│   │   └── NoteViewer.js   # SOAP note display
│   ├── package.json        # Node.js dependencies
│   └── .env.example        # Environment template
└── README.md
```

---

## 🔧 Function Details

### Lambda Functions

#### 1. `presign_url.py`
**Purpose**: Generate secure S3 upload URLs

**Trigger**: GET /presign
**Parameters**: 
- `fileName` (query parameter)

**Response**:
```json
{
  "url": "https://bucket.s3.amazonaws.com/file.wav?X-Amz-Algorithm=..."
}
```

**Key Features**:
- Input validation
- 5-minute URL expiration
- CORS headers
- Error handling

#### 2. `handler.py`
**Purpose**: Orchestrate audio processing and SOAP note generation

**Trigger**: POST /invoke
**Parameters**:
```json
{
  "audioFile": "filename.wav"
}
```

**Process Flow**:
1. Start Transcribe Medical job
2. Poll for completion (max 5 minutes)
3. Retrieve transcript from Transcribe
4. Send transcript to Bedrock for SOAP note generation
5. Save SOAP note to S3
6. Return results

**Response**:
```json
{
  "noteLocation": "https://bucket.s3.amazonaws.com/file_soap_note.txt",
  "transcript": "Patient reports...",
  "soapNote": "S: Patient reports...\nO: ...\nA: ...\nP: ..."
}
```

#### 3. `generate_note.py`
**Purpose**: Generate SOAP notes using Amazon Bedrock

**Function**: `generate_soap_note(transcript_text)`

**Bedrock Configuration**:
- Model: `anthropic.claude-3-sonnet-20240229-v1:0`
- Temperature: 0.3 (consistent medical output)
- Max tokens: 1000

**Prompt Template**:
```
Convert the following medical transcript into a SOAP note format:

Transcript:
{transcript_text}

Please format as:
S (Subjective): Patient's reported symptoms
O (Objective): Observable findings
A (Assessment): Clinical assessment
P (Plan): Treatment plan
```

### Frontend Components

#### 1. `App.js`
**Purpose**: Main application container

**State Management**:
- `noteData`: Stores transcript and SOAP note results

**Features**:
- Responsive design
- State management between components

#### 2. `UploadForm.js`
**Purpose**: Handle file upload and processing

**Features**:
- File type validation (wav, mp3, m4a)
- Progress indicators
- Error handling
- Environment-based API endpoint

**Process**:
1. Get presigned URL from API
2. Upload file directly to S3
3. Trigger processing via API
4. Display status updates

#### 3. `NoteViewer.js`
**Purpose**: Display transcript and SOAP note

**Features**:
- Dual display (transcript + SOAP note)
- Formatted medical content
- Download link for saved notes
- Responsive design

---

## 🛡️ Security Features

### Infrastructure Security
- **S3 Encryption**: AES256 server-side encryption
- **IAM Roles**: Least privilege access
- **Private S3**: No public access
- **Pre-signed URLs**: Temporary, secure uploads

### API Security
- **CORS**: Configured for frontend domain
- **Input Validation**: Parameter checking
- **Error Handling**: No sensitive data exposure

### Data Security
- **Encryption at Rest**: S3 server-side encryption
- **Encryption in Transit**: HTTPS/TLS
- **Temporary Access**: Pre-signed URLs expire in 5 minutes

---

## 🔍 Testing

### Manual Testing
1. **Upload Test**:
   - Upload a WAV audio file
   - Verify presigned URL generation
   - Confirm file appears in S3

2. **Processing Test**:
   - Trigger processing
   - Check CloudWatch logs
   - Verify transcript generation
   - Confirm SOAP note creation

3. **Frontend Test**:
   - Test file upload UI
   - Verify progress indicators
   - Check transcript/SOAP note display

### API Testing
```bash
# Test presign endpoint
curl "https://your-api-endpoint/presign?fileName=test.wav"

# Test invoke endpoint
curl -X POST "https://your-api-endpoint/invoke" \
  -H "Content-Type: application/json" \
  -d '{"audioFile": "test.wav"}'
```

---

## 📊 Monitoring

### CloudWatch Logs
- `/aws/lambda/genai_process_audio`: Processing logs
- `/aws/lambda/genai_presign_url`: URL generation logs

### Key Metrics
- Lambda duration
- Transcribe job success rate
- Bedrock API calls
- S3 upload success rate

---

## 🚨 Troubleshooting

### Common Issues

#### 1. Bedrock Access Denied
**Error**: `AccessDeniedException`
**Solution**: Request model access in Bedrock console

#### 2. S3 Bucket Already Exists
**Error**: `BucketAlreadyExists`
**Solution**: Change bucket name in variables.tf

#### 3. Lambda Timeout
**Error**: Task timed out
**Solution**: Increase timeout in main.tf (currently 300s)

#### 4. CORS Errors
**Error**: Cross-origin request blocked
**Solution**: Verify API Gateway CORS configuration

#### 5. Transcribe Job Failed
**Error**: Transcription failed
**Solution**: Check audio file format and size

### Debug Steps
1. Check CloudWatch logs
2. Verify IAM permissions
3. Test API endpoints individually
4. Validate file formats
5. Check Bedrock model access

---

## 💰 Cost Estimation

### Monthly Costs (Approximate)
- **Lambda**: $0.20 per 1M requests
- **Transcribe Medical**: $2.40 per hour of audio
- **Bedrock (Claude 3)**: $15 per 1M input tokens
- **S3**: $0.023 per GB storage
- **API Gateway**: $1.00 per 1M requests

**Example**: 100 audio files/month (5 min each) ≈ $15-25/month

---

## 🔄 CI/CD Pipeline (Future Enhancement)

### GitHub Actions Workflow
```yaml
name: Deploy GenAI Healthcare POC
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
      - name: Deploy Infrastructure
        run: |
          cd terraform
          terraform init
          terraform apply -auto-approve
```

---

## 📈 Future Enhancements

### Planned Features
- [ ] User authentication (Amazon Cognito)
- [ ] Multi-language support
- [ ] Batch processing
- [ ] Real-time transcription
- [ ] FHIR integration
- [ ] Audit logging
- [ ] Performance optimization

### Scalability Improvements
- [ ] DynamoDB for metadata
- [ ] SQS for async processing
- [ ] CloudFront for global distribution
- [ ] Auto-scaling configuration

---

## 📞 Support

### Contact Information
- **Developer**: Satish Patil, Sr Solution Architect
- **AWS Support**: Contact your AWS Account Manager
- **Issues**: Create GitHub issues for bugs/features

### Resources
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Amazon Transcribe Medical](https://docs.aws.amazon.com/transcribe/latest/dg/transcribe-medical.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 📄 License
MIT License - Free to use and modify for healthcare applications.

---

*Last Updated: December 2024*