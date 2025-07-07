import boto3
import json
import os

s3 = boto3.client('s3')
UPLOAD_BUCKET = os.environ['UPLOAD_BUCKET']

def lambda_handler(event, context):
    try:
        # List files in medical/ folder
        response = s3.list_objects_v2(Bucket=UPLOAD_BUCKET, Prefix='medical/')
        
        if 'Contents' not in response:
            return {
                'statusCode': 404,
                'headers': {'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'No files found'})
            }
        
        # Find latest transcript and SOAP note
        files = response['Contents']
        json_files = [f for f in files if f['Key'].endswith('.json')]
        soap_files = [f for f in files if f['Key'].endswith('_soap_note.txt')]
        
        if not json_files:
            return {
                'statusCode': 404,
                'headers': {'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'No transcript files found'})
            }
        
        # Get latest transcript
        latest_transcript = max(json_files, key=lambda x: x['LastModified'])
        transcript_key = latest_transcript['Key']
        
        # Get corresponding SOAP note
        soap_key = transcript_key.replace('.json', '_soap_note.txt')
        soap_file = next((f for f in soap_files if f['Key'] == soap_key), None)
        
        # Download transcript
        transcript_obj = s3.get_object(Bucket=UPLOAD_BUCKET, Key=transcript_key)
        transcript_data = json.loads(transcript_obj['Body'].read())
        transcript_text = transcript_data['results']['transcripts'][0]['transcript']
        
        result = {
            'transcript': transcript_text,
            'transcriptFile': transcript_key,
            'lastModified': latest_transcript['LastModified'].isoformat()
        }
        
        # Download SOAP note if exists
        if soap_file:
            soap_obj = s3.get_object(Bucket=UPLOAD_BUCKET, Key=soap_key)
            soap_note = soap_obj['Body'].read().decode('utf-8')
            result['soapNote'] = soap_note
            result['soapFile'] = soap_key
            result['status'] = 'completed'
        else:
            result['status'] = 'processing'
            result['message'] = 'SOAP note is being generated...'
        
        return {
            'statusCode': 200,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps(result)
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }