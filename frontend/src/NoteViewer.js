import React from 'react';

export default function NoteViewer({ noteData }) {
  if (!noteData) {
    return (
      <div style={{ padding: 20, textAlign: 'center', color: '#666' }}>
        <p>Upload an audio file to generate a SOAP note</p>
      </div>
    );
  }

  return (
    <div style={{ marginTop: 20 }}>
      {noteData.transcript && (
        <div style={{ marginBottom: 20, padding: 15, backgroundColor: '#f5f5f5', borderRadius: 8 }}>
          <h3>Transcript</h3>
          <p style={{ whiteSpace: 'pre-wrap' }}>{noteData.transcript}</p>
        </div>
      )}
      
      {noteData.soapNote && (
        <div style={{ padding: 15, backgroundColor: '#e8f5e8', borderRadius: 8 }}>
          <h3>SOAP Note</h3>
          <pre style={{ whiteSpace: 'pre-wrap', fontFamily: 'inherit' }}>{noteData.soapNote}</pre>
        </div>
      )}
      
      {noteData.noteLocation && (
        <div style={{ marginTop: 10, textAlign: 'center' }}>
          <a href={noteData.noteLocation} target="_blank" rel="noopener noreferrer">
            Download SOAP Note
          </a>
        </div>
      )}
    </div>
  );
}

