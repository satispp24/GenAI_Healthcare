#!/bin/bash
# User data script for GenAI Healthcare POC Frontend EC2

# Enable logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user data script at $(date)"

# Update system
yum update -y

# Install nginx using Amazon Linux Extras
amazon-linux-extras install nginx1 -y

# Install git
yum install -y git

# Create app directory
mkdir -p /opt/genai-frontend
cd /opt/genai-frontend

# Create functional HTML page with API integration
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>GenAI Healthcare POC by Satish Patil</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .upload { padding: 20px; background: #f0f8ff; border-radius: 8px; margin: 20px 0; }
        .status { padding: 15px; margin: 15px 0; border-radius: 5px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background: #cce7ff; color: #004085; border: 1px solid #b3d7ff; }
        button { background: #007cba; color: white; border: none; padding: 12px 24px; border-radius: 5px; cursor: pointer; font-size: 16px; }
        button:hover { background: #005a87; }
        button:disabled { background: #ccc; cursor: not-allowed; }
        input[type="file"] { margin: 10px 0; padding: 8px; }
        .results { margin-top: 30px; }
        .transcript, .soap-note { background: #f8f9fa; padding: 20px; margin: 15px 0; border-radius: 8px; border-left: 4px solid #007cba; }
        .soap-note { border-left-color: #28a745; }
        pre { white-space: pre-wrap; font-family: inherit; }
        .emoji { font-size: 1.2em; margin-right: 8px; }
        h1 .emoji { font-size: 1.5em; }
        h3 .emoji { font-size: 1.1em; }
    </style>
</head>
<body>
    <div class="container">
        <h1><span class="emoji">🧠</span>GenAI Healthcare POC</h1>
        <p>Upload audio files to generate SOAP notes using AI</p>
        <div style="text-align: center; margin: 20px 0; padding: 15px; background: #f8f9fa; border-radius: 8px; border-left: 4px solid #007cba;">
            <p style="margin: 0; font-weight: bold; color: #007cba;">👨‍💻 Developed by <strong>Satish Patil</strong></p>
            <p style="margin: 5px 0 0 0; font-size: 14px; color: #666;">Senior Solution Architect | GenAI Healthcare Solutions</p>
        </div>
        
        <div class="upload">
            <h3><span class="emoji">📁</span>Upload Audio File</h3>
            <input type="file" accept="audio/wav,audio/mp3,audio/m4a" id="audioFile">
            <br>
            <button onclick="processAudio()" id="uploadBtn"><span class="emoji">🚀</span>Upload & Generate SOAP Note</button>
            <button onclick="checkResults()" id="checkBtn" style="display: none; margin-left: 10px;"><span class="emoji">🔄</span>Check Results</button>
            <div id="status"></div>
        </div>
        
        <div id="results" class="results" style="display: none;">
            <div id="transcript" class="transcript">
                <h3><span class="emoji">📝</span>Transcript</h3>
                <div id="transcriptContent"></div>
            </div>
            <div id="soapNote" class="soap-note">
                <h3><span class="emoji">🏥</span>SOAP Note</h3>
                <pre id="soapContent"></pre>
            </div>
        </div>
    </div>

    <script>
        
        async function processAudio() {
            const fileInput = document.getElementById('audioFile');
            const uploadBtn = document.getElementById('uploadBtn');
            const statusDiv = document.getElementById('status');
            const resultsDiv = document.getElementById('results');
            
            if (!fileInput.files.length) {
                showStatus('Please select an audio file first.', 'error');
                return;
            }
            
            const file = fileInput.files[0];
            uploadBtn.disabled = true;
            uploadBtn.innerHTML = '<span class="emoji">🔄</span>Processing...';
            resultsDiv.style.display = 'none';
            
            try {
                showStatus('📤 Converting file to base64...', 'info');
                const base64Data = await fileToBase64(file);
                
                showStatus('⬆️ Uploading and starting transcription...', 'info');
                const response = await fetch('https://b43vu3eud1.execute-api.us-east-1.amazonaws.com/upload-only', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        fileName: file.name,
                        fileData: base64Data,
                        contentType: file.type || 'audio/wav'
                    })
                });
                
                if (!response.ok) {
                    const errorData = await response.json();
                    throw new Error(errorData.error || 'Upload failed');
                }
                
                const result = await response.json();
                
                if (result.success) {
                    showStatus('✅ Upload successful! Transcription started.', 'success');
                    showStatus('🔄 Auto-checking for results every 30 seconds...', 'info');
                    
                    // Show check button
                    document.getElementById('checkBtn').style.display = 'inline-block';
                    
                    // Start checking for results immediately
                    checkResults();
                } else {
                    throw new Error(result.error || 'Upload failed');
                }
                
            } catch (error) {
                showStatus(`❌ Error: ${error.message}`, 'error');
            } finally {
                uploadBtn.disabled = false;
                uploadBtn.innerHTML = '<span class="emoji">🚀</span>Upload & Generate SOAP Note';
            }
        }
        
        function showStatus(message, type) {
            document.getElementById('status').innerHTML = `<div class="status ${type}">${message}</div>`;
        }
        
        function displayResults(result) {
            const resultsDiv = document.getElementById('results');
            if (result.transcript) {
                document.getElementById('transcriptContent').textContent = result.transcript;
            }
            if (result.soapNote) {
                document.getElementById('soapContent').textContent = result.soapNote;
            }
            resultsDiv.style.display = 'block';
        }
        
        function fileToBase64(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.readAsDataURL(file);
                reader.onload = () => resolve(reader.result.split(',')[1]);
                reader.onerror = error => reject(error);
            });
        }
        
        async function checkResults() {
            try {
                showStatus('🔍 Checking for results...', 'info');
                const response = await fetch('https://b43vu3eud1.execute-api.us-east-1.amazonaws.com/get-results');
                
                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}`);
                }
                
                const result = await response.json();
                console.log('Results:', result);
                
                if (result.status === 'completed' && result.soapNote) {
                    showStatus('✅ SOAP note generated successfully!', 'success');
                    displayResults(result);
                    document.getElementById('checkBtn').style.display = 'none';
                } else if (result.transcript) {
                    showStatus('📝 Transcript ready, generating SOAP note...', 'info');
                    setTimeout(() => checkResults(), 15000); // Check every 15 seconds
                } else {
                    showStatus('🔄 Still transcribing... Checking again in 30 seconds.', 'info');
                    setTimeout(() => checkResults(), 30000);
                }
            } catch (error) {
                console.log('Error checking results:', error);
                showStatus(`⚠️ Error checking results: ${error.message}. Retrying...`, 'error');
                setTimeout(() => checkResults(), 30000);
            }
        }
        
        document.getElementById('audioFile').addEventListener('change', function() {
            if (this.files.length > 0) {
                const file = this.files[0];
                const fileSize = (file.size / 1024 / 1024).toFixed(2);
                showStatus(`📁 File selected: ${file.name} (${fileSize} MB)`, 'info');
            }
        });
    </script>
</body>
</html>
EOF



# Create nginx web directory
mkdir -p /usr/share/nginx/html

# Copy HTML to nginx directory
cp index.html /usr/share/nginx/html/

# Configure nginx
cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;
        index        index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
EOF

# Start and enable services
systemctl start nginx
systemctl enable nginx

# Set permissions
chown -R nginx:nginx /usr/share/nginx/html
chmod -R 755 /usr/share/nginx/html

# Create simple update script
cat > /opt/update-frontend.sh << 'EOF'
#!/bin/bash
echo "Updating GenAI Frontend..."
systemctl restart nginx
echo "Frontend updated!"
EOF

chmod +x /opt/update-frontend.sh

# Test nginx configuration
nginx -t

# Check if nginx is running
systemctl status nginx

# Check if port 80 is listening
netstat -tlnp | grep :80

echo "GenAI Healthcare POC Frontend deployment completed at $(date)!"
echo "Nginx status: $(systemctl is-active nginx)"
echo "Web directory contents:"
ls -la /usr/share/nginx/html/