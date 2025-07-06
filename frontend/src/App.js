import React, { useState } from 'react';
import UploadForm from './UploadForm';
import NoteViewer from './NoteViewer';

function App() {
  const [noteUrl, setNoteUrl] = useState(null);

  return (
    <div style={{ maxWidth: 600, margin: 'auto', padding: 20 }}>
      <h1>GenAI Healthcare POC</h1>
      <UploadForm onUploadComplete={setNoteUrl} />
      <NoteViewer noteUrl={noteUrl} />
    </div>
  );
}

export default App;

