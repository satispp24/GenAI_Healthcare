# 🔧 API Endpoint Update Instructions

## 📍 Current API Endpoint
```
https://b43vu3eud1.execute-api.us-east-1.amazonaws.com
```

## 📂 Files That Need API Endpoint Updates

### 1. Frontend (user_data.sh)
**Location**: `terraform/user_data.sh`
**Lines to Update**:
- Line ~85: `/upload-only` endpoint
- Line ~145: `/get-results` endpoint

```javascript
// Current endpoints in frontend:
const response = await fetch('https://b43vu3eud1.execute-api.us-east-1.amazonaws.com/upload-only', {
const response = await fetch('https://b43vu3eud1.execute-api.us-east-1.amazonaws.com/get-results');
```

### 2. README.md
**Location**: `README.md`
**Sections to Update**:
- Live System Status
- API Endpoints section
- Test commands
- Debug commands

```markdown
# Current references in README:
- **API Gateway**: https://b43vu3eud1.execute-api.us-east-1.amazonaws.com
```

### 3. Test Scripts
**Location**: `lambda/test_*.py`
**Files to Check**:
- Any hardcoded API endpoints in test scripts

## 🔄 How to Update API Endpoint

### Step 1: Get New API Endpoint
```bash
cd terraform
terraform output api_endpoint
```

### Step 2: Update Frontend
```bash
# Edit terraform/user_data.sh
# Replace all instances of:
# https://b43vu3eud1.execute-api.us-east-1.amazonaws.com
# With your new API endpoint
```

### Step 3: Update Documentation
```bash
# Edit README.md
# Replace API endpoint references
```

### Step 4: Deploy Changes
```bash
cd terraform
terraform apply -auto-approve
```

## ⚠️ Important Notes

1. **Terraform Output**: Always use `terraform output api_endpoint` to get the correct endpoint
2. **Multiple Files**: The API endpoint appears in multiple files - update all of them
3. **Case Sensitive**: API Gateway IDs are case-sensitive
4. **Region Specific**: Endpoint includes region (us-east-1)
5. **HTTPS Only**: Always use HTTPS, never HTTP

## 🧪 Testing After Update

```bash
# Test presign endpoint
curl "https://YOUR-NEW-ENDPOINT/presign?fileName=test.wav"

# Test upload-only endpoint
curl -X POST "https://YOUR-NEW-ENDPOINT/upload-only" \
  -H "Content-Type: application/json" \
  -d '{"fileName": "test.wav", "fileData": "dGVzdA==", "contentType": "audio/wav"}'

# Test get-results endpoint
curl "https://YOUR-NEW-ENDPOINT/get-results"
```

## 📋 Checklist

- [ ] Get new API endpoint from terraform output
- [ ] Update terraform/user_data.sh (2 locations)
- [ ] Update README.md (multiple locations)
- [ ] Update any test scripts
- [ ] Deploy with terraform apply
- [ ] Test all endpoints
- [ ] Verify frontend functionality

## 🔍 Search and Replace

Use this command to find all API endpoint references:
```bash
grep -r "b43vu3eud1.execute-api.us-east-1.amazonaws.com" .
```

Replace with your new endpoint across all files.