import React, { useState } from "react";
import { uploadFile } from "../services/api";
import { Button, LinearProgress } from "@mui/material";

const FileUpload = ({ onUploadComplete }) => {
  const [file, setFile] = useState(null);
  const [progress, setProgress] = useState(false);

  const handleFileChange = (e) => setFile(e.target.files[0]);

  const handleUpload = async () => {
    if (file) {
      setProgress(true);
      try {
        await uploadFile(file);
        onUploadComplete();
      } catch (error) {
        console.error("Upload failed:", error);
      } finally {
        setProgress(false);
      }
    }
  };

  return (
    <div>
      <input type="file" onChange={handleFileChange} />
      <Button variant="contained" onClick={handleUpload} disabled={!file}>
        Upload
      </Button>
      {progress && <LinearProgress />}
    </div>
  );
};

export default FileUpload;
