import boto3
import os
import json
import base64
import time

s3 = boto3.client('s3')
transcribe = boto3.client('transcribe')

UPLOAD_BUCKET = os.environ['UPLOAD_BUCKET']

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        file_name = body['fileName']
        file_data = body['fileData']
        content_type = body.get('contentType', 'audio/wav')
        
        # Decode and upload to S3
        audio_bytes = base64.b64decode(file_data)
        s3.put_object(
            Bucket=UPLOAD_BUCKET,
            Key=file_name,
            Body=audio_bytes,
            ContentType=content_type
        )
        
        # Start transcription job
        job_name = f"medtrans-{int(time.time())}"
        audio_uri = f"s3://{UPLOAD_BUCKET}/{file_name}"
        
        file_ext = file_name.lower().split('.')[-1]
        media_format = 'wav' if file_ext == 'wav' else 'mp4' if file_ext in ['m4a', 'mp4'] else 'mp3'
        
        transcribe.start_medical_transcription_job(
            MedicalTranscriptionJobName=job_name,
            LanguageCode='en-US',
            MediaFormat=media_format,
            Media={'MediaFileUri': audio_uri},
            OutputBucketName=UPLOAD_BUCKET,
            Specialty='PRIMARYCARE',
            Type='CONVERSATION'
        )
        
        print(f"🎤 Started transcription job: {job_name}")
        
        return {
            'statusCode': 200,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'success': True,
                'message': 'Audio uploaded and transcription started',
                'jobName': job_name,
                'fileName': file_name
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }