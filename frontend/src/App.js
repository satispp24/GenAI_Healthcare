import React, { useState } from 'react';
import UploadForm from './UploadForm';
import NoteViewer from './NoteViewer';

function App() {
  const [noteData, setNoteData] = useState(null);

  return (
    <div style={{ maxWidth: 800, margin: 'auto', padding: 20 }}>
      <h1>🧠 GenAI Healthcare POC</h1>
      <p>Upload audio files to generate SOAP notes using AI</p>
      <UploadForm onUploadComplete={setNoteData} />
      <NoteViewer noteData={noteData} />
    </div>
  );
}

export default App;

