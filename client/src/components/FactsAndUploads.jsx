import React, { useState } from "react";

/**
 * FactsAndUploads - Allows user to upload text-based documents,
 * which the server then chunks, embeds, and stores (both in DB & Pinecone).
 *
 * currentProjectId - ID of the current "single case" project
 */
const FactsAndUploads = ({ currentProjectId }) => {
  const [fileName, setFileName] = useState("");
  const [category, setCategory] = useState("discovery");
  const [content, setContent] = useState("");
  const [uploadStatus, setUploadStatus] = useState("");

  const handleUpload = async () => {
    if (!currentProjectId || !content.trim()) {
      setUploadStatus("No projectId or content provided.");
      return;
    }

    try {
      const res = await fetch("http://localhost:3001/api/upload", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          projectId: currentProjectId,
          fileName,
          category,
          content
        }),
      });
      const data = await res.json();
      if (res.ok) {
        setUploadStatus(data.message || "Upload complete.");
      } else {
        setUploadStatus(\`Error: \${data.error || "Unknown error."}\`);
      }
    } catch (error) {
      console.error("Upload error", error);
      setUploadStatus("Error uploading file.");
    }
  };

  return (
    <div className="facts-uploads-container">
      <h2>Facts & Uploads</h2>
      <div style={{ marginBottom: "1rem" }}>
        <label>File Name (Optional):</label>
        <input
          type="text"
          placeholder="E.g. transcript_2023-04-10.txt"
          value={fileName}
          onChange={(e) => setFileName(e.target.value)}
          style={{ display: "block", marginBottom: "0.5rem" }}
        />
        <label>Category:</label>
        <select
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          style={{ display: "block", marginBottom: "0.5rem" }}
        >
          <option value="discovery">Discovery</option>
          <option value="transcript">Transcript</option>
          <option value="communication">Communication</option>
          <option value="motion">Motion</option>
          <option value="other">Other</option>
        </select>
      </div>

      <label>Document Text:</label>
      <textarea
        placeholder="Paste document content here..."
        value={content}
        onChange={(e) => setContent(e.target.value)}
        rows={6}
        style={{ width: "100%", marginBottom: "0.5rem" }}
      />

      <button onClick={handleUpload}>Upload</button>
      {uploadStatus && <p style={{ marginTop: "1rem" }}>{uploadStatus}</p>}
    </div>
  );
};

export default FactsAndUploads;
