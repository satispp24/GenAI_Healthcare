import boto3
import os
import json
import time
import base64
import urllib.request
from generate_note import generate_soap_note

s3 = boto3.client('s3')
transcribe = boto3.client('transcribe')

UPLOAD_BUCKET = os.environ['UPLOAD_BUCKET']

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        file_name = body['fileName']
        file_data = body['fileData']  # base64 encoded
        content_type = body.get('contentType', 'audio/wav')
        
        # Decode base64 file data
        audio_bytes = base64.b64decode(file_data)
        
        # Upload to S3
        s3.put_object(
            Bucket=UPLOAD_BUCKET,
            Key=file_name,
            Body=audio_bytes,
            ContentType=content_type
        )
        
        # Start transcription
        job_name = f"medtrans-{int(time.time())}"
        audio_uri = f"s3://{UPLOAD_BUCKET}/{file_name}"
        
        # Determine format from file extension
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
        
        # Wait for completion
        for _ in range(60):
            status = transcribe.get_medical_transcription_job(MedicalTranscriptionJobName=job_name)
            job_status = status['MedicalTranscriptionJob']['TranscriptionJobStatus']
            
            if job_status == 'COMPLETED':
                transcript_uri = status['MedicalTranscriptionJob']['Transcript']['TranscriptFileUri']
                
                # Get transcript content
                with urllib.request.urlopen(transcript_uri) as response:
                    transcript_data = json.loads(response.read())
                    transcript_text = transcript_data['results']['transcripts'][0]['transcript']
                
                # Generate SOAP note using Bedrock
                soap_note = generate_soap_note(transcript_text)
                
                # Save SOAP note
                note_key = file_name.replace(f'.{file_ext}', '_soap_note.txt')
                s3.put_object(Bucket=UPLOAD_BUCKET, Key=note_key, Body=soap_note)
                
                print(f"✅ Complete workflow successful:")
                print(f"📁 Audio: {file_name}")
                print(f"📝 Transcript: {len(transcript_text)} characters")
                print(f"🏥 SOAP Note: {len(soap_note)} characters")
                print(f"💾 Saved to: {note_key}")
                
                return {
                    'statusCode': 200,
                    'headers': {
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Methods': 'POST, OPTIONS',
                        'Access-Control-Allow-Headers': 'Content-Type'
                    },
                    'body': json.dumps({
                        'success': True,
                        'message': 'Audio processed successfully - Transcript generated and SOAP note created',
                        'noteLocation': f"https://{UPLOAD_BUCKET}.s3.amazonaws.com/{note_key}",
                        'transcript': transcript_text,
                        'soapNote': soap_note,
                        'processingTime': f"{int(time.time()) - int(job_name.split('-')[1])} seconds"
                    })
                }
            
            elif job_status == 'FAILED':
                return {
                    'statusCode': 500,
                    'headers': {'Access-Control-Allow-Origin': '*'},
                    'body': json.dumps({'error': 'Transcription failed'})
                }
            
            time.sleep(10)
        
        # Timeout
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Transcription timed out'})
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': f'Processing failed: {str(e)}'})
        }