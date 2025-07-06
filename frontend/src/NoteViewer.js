import React from 'react';

export default function NoteViewer({ noteUrl }) {
  return (
    <div>
      {noteUrl ? (
        <iframe
          src={noteUrl}
          title="SOAP Note"
          style={{ width: '100%', height: '400px', border: 'none' }}
        />
      ) : (
        <p>No note available</p>
      )}
    </div>
  );
}

