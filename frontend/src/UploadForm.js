import React, { useState } from 'react';
import axios from 'axios';

export default function UploadForm({ onUploadComplete }) {
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);

  const handleUpload = async () => {
    setUploading(true);
    try {
      const presignRes = await axios.get(
        `https://YOUR_API_GATEWAY_ENDPOINT/presign?fileName=${file.name}`
      );
      const url = presignRes.data.url;

      await axios.put(url, file, {
        headers: { 'Content-Type': 'audio/wav' }
      });

      const invokeRes = await axios.post(
        `https://YOUR_API_GATEWAY_ENDPOINT/invoke`,
        { audioFile: file.name }
      );

      onUploadComplete(invokeRes.data.noteLocation);
    } catch (err) {
      alert('Upload failed: ' + err.message);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div>
      <input
        type="file"
        accept="audio/wav"
        onChange={e => setFile(e.target.files[0])}
        disabled={uploading}
      />
      <button onClick={handleUpload} disabled={uploading || !file}>
        {uploading ? 'Uploading...' : 'Upload & Process'}
      </button>
    </div>
  );
}

