#!/usr/bin/env bash
# create_structure.sh
# --------------------------------------------------------------------
# This script creates all folders and files (in their final versions)
# from the entire chat history. Run it inside an empty project folder
# to reconstruct the full server/ and client/ structure.
# --------------------------------------------------------------------

set -e

echo "=== Creating server directory structure ==="
mkdir -p server/config
mkdir -p server/models
mkdir -p server/routes
mkdir -p server/utils

echo "=== Creating client directory structure ==="
mkdir -p client/src
mkdir -p client/src/components
mkdir -p client/src/utils

# ---------------------------
# 1. server/config/database.js
# ---------------------------
cat << 'EOF' > server/config/database.js
const mongoose = require("mongoose");

async function connectDB() {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI, {
      // Add any custom Mongoose connection options here
    });
    console.log(\`MongoDB connected: \${conn.connection.host}\`);
  } catch (err) {
    console.error("MongoDB connection error:", err);
    process.exit(1);
  }
}

module.exports = connectDB;
EOF

# ---------------------------
# 2. server/pinecone.js
# ---------------------------
cat << 'EOF' > server/pinecone.js
const { PineconeClient } = require("@pinecone-database/pinecone");

const pinecone = new PineconeClient();

async function initPinecone() {
  try {
    await pinecone.init({
      apiKey: process.env.PINECONE_API_KEY,
      environment: process.env.PINECONE_ENV // e.g. "us-west1-gcp"
    });
    console.log("Pinecone initialized successfully.");
  } catch (error) {
    console.error("Error initializing Pinecone:", error);
    process.exit(1);
  }
}

module.exports = { pinecone, initPinecone };
EOF

# ---------------------------
# 3. server/package.json
# ---------------------------
cat << 'EOF' > server/package.json
{
  "name": "legalchat-server",
  "version": "1.0.0",
  "description": "Server for the Single-Case LegalChat application",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "express": "^4.18.2",
    "mongoose": "^6.10.0",
    "node-fetch": "^2.6.7",
    "@pinecone-database/pinecone": "^0.0.10"
  }
}
EOF

# ---------------------------
# 4. server/.env (template)
# ---------------------------
cat << 'EOF' > server/.env
# DO NOT COMMIT REAL SECRETS TO VERSION CONTROL

OPENAI_API_KEY=your-openai-key-here
MONGO_URI=mongodb+srv://your-user:your-pass@cluster.example.net/dbName
PINECONE_API_KEY=your-pinecone-api-key
PINECONE_ENV=us-west1-gcp  # or whichever environment your Pinecone index is in

# If you use any other environment variables, list them here
EOF

# ---------------------------
# 5. server/server.js
# ---------------------------
cat << 'EOF' > server/server.js
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const connectDB = require("./config/database");
const { initPinecone } = require("./pinecone");

// Routes
const projectRoutes = require("./routes/project");
const uploadRoutes = require("./routes/upload");
const chatRoutes = require("./routes/chat");
const casesRoutes = require("./routes/cases");
// (Optional) Could import SSE or streaming routes if you have them

const app = express();

// 1. Connect to MongoDB
connectDB();

// 2. Initialize Pinecone
initPinecone();

// 3. Middleware
app.use(cors());
app.use(express.json());

// 4. Use Routes
app.use("/api/projects", projectRoutes);  // e.g. create/read project data
app.use("/api/upload", uploadRoutes);     // handle doc uploads & embeddings
app.use("/api/chat", chatRoutes);         // retrieval-augmented chat
app.use("/api/cases", casesRoutes);       // external case references

// 5. Start Server
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(\`Server is running on port \${PORT}\`);
});
EOF

# ---------------------------
# 6. server/models/Project.js
# ---------------------------
cat << 'EOF' > server/models/Project.js
const mongoose = require("mongoose");

const ProjectSchema = new mongoose.Schema({
  title: String,           // e.g., "Smith v. Doe"
  docketNumber: String,    // e.g., "1:23-cv-456"
  description: String,     // Optional summary/description of this case
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Project", ProjectSchema);
EOF

# ---------------------------
# 7. server/models/Document.js
# ---------------------------
cat << 'EOF' > server/models/Document.js
const mongoose = require("mongoose");

const DocumentSchema = new mongoose.Schema({
  projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project" },
  fileName: String,                       // Original file name or user-given title
  category: {
    type: String,
    enum: ["discovery", "transcript", "communication", "motion", "other"],
    default: "other"
  },
  content: String,                        // Extracted text content (if stored)
  uploadedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Document", DocumentSchema);
EOF

# ---------------------------
# 8. server/models/DocumentChunk.js
# ---------------------------
cat << 'EOF' > server/models/DocumentChunk.js
const mongoose = require("mongoose");

const DocumentChunkSchema = new mongoose.Schema({
  documentId: { type: mongoose.Schema.Types.ObjectId, ref: "Document" },
  chunkIndex: Number,       // The index/order of this chunk in the original doc
  text: String,             // The text content of this chunk
  pineconeId: String,       // The vector ID in Pinecone (or another vector DB)
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("DocumentChunk", DocumentChunkSchema);
EOF

# ---------------------------
# 9. server/models/ChatMessage.js
# ---------------------------
cat << 'EOF' > server/models/ChatMessage.js
const mongoose = require("mongoose");

const ChatMessageSchema = new mongoose.Schema({
  projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project" },
  sender: { type: String, enum: ["user", "ai"] },
  text: String,
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("ChatMessage", ChatMessageSchema);
EOF

# ---------------------------
# 10. server/routes/project.js
# ---------------------------
cat << 'EOF' > server/routes/project.js
const express = require("express");
const router = express.Router();
const Project = require("../models/Project");

// Create a new Project (single-case)
router.post("/", async (req, res) => {
  try {
    const { title, docketNumber, description } = req.body;
    const project = await Project.create({ title, docketNumber, description });
    res.json(project);
  } catch (err) {
    console.error("Error creating project:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get an existing Project by ID
router.get("/:projectId", async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    if (!project) {
      return res.status(404).json({ error: "Project not found." });
    }
    res.json(project);
  } catch (err) {
    console.error("Error fetching project:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
EOF

# ---------------------------
# 11. server/routes/upload.js
# ---------------------------
cat << 'EOF' > server/routes/upload.js
const express = require("express");
const router = express.Router();
const Document = require("../models/Document");
const DocumentChunk = require("../models/DocumentChunk");
const { pinecone } = require("../pinecone");
const { createEmbeddings } = require("../utils/embeddings");
const { splitIntoChunks } = require("../utils/chunker");

/**
 * POST /api/upload
 * Receives document content, stores it in MongoDB, chunks & embeds it, 
 * then upserts vectors to Pinecone (or another vector DB).
 */
router.post("/", async (req, res) => {
  try {
    const { projectId, fileName, category, content } = req.body;
    if (!projectId || !content) {
      return res.status(400).json({ error: "Missing projectId or document content." });
    }

    // 1. Create a new Document in MongoDB
    const doc = await Document.create({
      projectId,
      fileName,
      category,
      content
    });

    // 2. Split content into chunks
    const chunks = splitIntoChunks(content, 500); // Example: ~500 chars or tokens

    // 3. Generate embeddings for each chunk
    const embeddings = await createEmbeddings(chunks);

    // 4. Upsert these vectors into Pinecone
    const pineconeIndex = pinecone.Index("legalcase-index");
    const vectors = embeddings.map((emb, i) => ({
      id: \`\${doc._id.toString()}-chunk-\${i}\`,
      values: emb.embedding,
      metadata: {
        documentId: doc._id.toString(),
        chunkIndex: i,
        chunkText: chunks[i],
        fileName
      }
    }));
    await pineconeIndex.upsert({ upsertRequest: { vectors } });

    // 5. Store chunk references in MongoDB
    for (let i = 0; i < chunks.length; i++) {
      await DocumentChunk.create({
        documentId: doc._id,
        chunkIndex: i,
        text: chunks[i],
        pineconeId: \`\${doc._id.toString()}-chunk-\${i}\`
      });
    }

    res.json({ message: "File uploaded & embedded successfully.", docId: doc._id });
  } catch (err) {
    console.error("Upload error:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
EOF

# ---------------------------
# 12. server/routes/chat.js
# ---------------------------
cat << 'EOF' > server/routes/chat.js
const express = require("express");
const router = express.Router();
const fetch = require("node-fetch");
const { pinecone } = require("../pinecone");
// Optional: ChatMessage model if you want to store conversation history
// const ChatMessage = require("../models/ChatMessage");

const { OPENAI_API_KEY } = process.env;

/**
 * POST /api/chat
 * Example retrieval-augmented chat (non-streaming).
 * 1) Embed user query
 * 2) Query Pinecone
 * 3) Build GPT-4 prompt with relevant chunks
 * 4) Return AI response
 */
router.post("/", async (req, res) => {
  try {
    const { projectId, userMessage } = req.body;
    if (!projectId || !userMessage) {
      return res.status(400).json({ error: "Missing projectId or userMessage." });
    }

    // 1. Generate embedding for user query
    const embedRes = await fetch("https://api.openai.com/v1/embeddings", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: \`Bearer \${OPENAI_API_KEY}\`
      },
      body: JSON.stringify({
        input: userMessage,
        model: "text-embedding-ada-002"
      })
    });
    const embedJson = await embedRes.json();
    const userQueryEmbedding = embedJson.data[0].embedding;

    // 2. Query Pinecone for relevant chunks
    const pineconeIndex = pinecone.Index("legalcase-index");
    const queryResponse = await pineconeIndex.query({
      queryRequest: {
        vector: userQueryEmbedding,
        topK: 3,
        includeMetadata: true
      }
    });

    // 3. Construct the context from the top matches
    const relevantChunks = queryResponse.matches.map(m => m.metadata.chunkText);
    const combinedContext = relevantChunks.join("\n\n---\n\n");

    // 4. Build the prompt for GPT-4
    const systemPrompt = `
      You are a helpful legal research assistant for a single court case.
      Use the following relevant text from the user's documents to help answer their question.
      If some details are not in the text, say so or indicate uncertainty.

      Relevant Documents:
      ${combinedContext}

      ------------------
      When you answer, reference the text above if it applies.
    `;

    // 5. Call GPT-4 (non-streaming example)
    const completionRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: \`Bearer \${OPENAI_API_KEY}\`
      },
      body: JSON.stringify({
        model: "gpt-4",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userMessage }
        ],
        max_tokens: 1024,
        temperature: 0.7
      })
    });
    const completionJson = await completionRes.json();
    const aiResponse = completionJson.choices[0].message.content;

    // (Optional) Store the conversation in ChatMessage if desired
    // await ChatMessage.create({ projectId, sender: "user", text: userMessage });
    // await ChatMessage.create({ projectId, sender: "ai", text: aiResponse });

    res.json({
      response: aiResponse,
      relevantChunks
    });
  } catch (err) {
    console.error("Chat error:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
EOF

# ---------------------------
# 13. server/routes/cases.js
# ---------------------------
cat << 'EOF' > server/routes/cases.js
const express = require("express");
const router = express.Router();

/**
 * GET /api/cases
 * Example: returns mock or external references for relevant case law
 */
router.get("/", (req, res) => {
  const sampleCases = [
    {
      caseTitle: "Robinson v. De Niro",
      docketNumber: "1:19-cv-09156 (S.D.N.Y., Jul 8, 2021)",
      snippet: "Discusses 'faithless servant doctrine' in detail...",
    },
    {
      caseTitle: "Doe v. ExampleCorp",
      docketNumber: "2:21-cv-04234 (C.D.Cal., Jan 15, 2022)",
      snippet: "Addresses breach of fiduciary duty under California law...",
    }
  ];
  res.json(sampleCases);
});

module.exports = router;
EOF

# ---------------------------
# 14. server/utils/embeddings.js
# ---------------------------
cat << 'EOF' > server/utils/embeddings.js
const fetch = require("node-fetch");
const { OPENAI_API_KEY } = process.env;

/**
 * createEmbeddings(chunks: string[])
 * Sends an array of text chunks to OpenAI's Embeddings API.
 * Returns an array: [{ embedding, index }, ...].
 */
async function createEmbeddings(chunks) {
  if (!Array.isArray(chunks) || chunks.length === 0) {
    return [];
  }

  // OpenAI Embeddings endpoint allows multiple inputs
  const response = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: \`Bearer \${OPENAI_API_KEY}\`
    },
    body: JSON.stringify({
      model: "text-embedding-ada-002",
      input: chunks
    })
  });

  const json = await response.json();
  if (!json.data) {
    throw new Error("Failed to create embeddings: " + JSON.stringify(json));
  }

  // Match each embedding vector to its corresponding chunk by index
  return json.data.map((item, i) => ({
    embedding: item.embedding,
    index: i
  }));
}

module.exports = { createEmbeddings };
EOF

# ---------------------------
# 15. server/utils/chunker.js
# ---------------------------
cat << 'EOF' > server/utils/chunker.js
/**
 * splitIntoChunks(content: string, chunkSize: number)
 * A simple utility that splits text into smaller pieces by length.
 * For a more robust approach, consider counting tokens (using e.g. GPT tokenizers).
 */
function splitIntoChunks(content, chunkSize = 500) {
  const chunks = [];
  let startIndex = 0;

  while (startIndex < content.length) {
    const endIndex = startIndex + chunkSize;
    const chunk = content.slice(startIndex, endIndex);
    chunks.push(chunk);
    startIndex = endIndex;
  }

  return chunks;
}

module.exports = { splitIntoChunks };
EOF

# ---------------------------
# 16. server/utils/retrieval.js
# ---------------------------
cat << 'EOF' > server/utils/retrieval.js
// This file is optional but shows how you might refactor retrieval logic 
// into a separate helper instead of inline in the chat route.

const fetch = require("node-fetch");
const { pinecone } = require("../pinecone");
const { OPENAI_API_KEY } = process.env;

/**
 * generateQueryEmbeddingAndSearchPinecone(userMessage: string, topK = 3)
 * 1. Create user query embedding via OpenAI
 * 2. Query Pinecone for topK relevant chunks
 * 3. Return { combinedContext, relevantChunks }
 */
async function generateQueryEmbeddingAndSearchPinecone(userMessage, topK = 3) {
  // 1. Embed user query
  const embedRes = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: \`Bearer \${OPENAI_API_KEY}\`
    },
    body: JSON.stringify({
      model: "text-embedding-ada-002",
      input: userMessage
    })
  });
  const embedJson = await embedRes.json();
  const userQueryEmbedding = embedJson.data[0].embedding;

  // 2. Query Pinecone
  const pineconeIndex = pinecone.Index("legalcase-index");
  const queryResponse = await pineconeIndex.query({
    queryRequest: {
      vector: userQueryEmbedding,
      topK,
      includeMetadata: true
    }
  });

  // 3. Construct context
  const relevantChunks = queryResponse.matches.map((m) => m.metadata.chunkText);
  const combinedContext = relevantChunks.join("\n\n---\n\n");
  
  return { combinedContext, relevantChunks };
}

module.exports = { generateQueryEmbeddingAndSearchPinecone };
EOF

# --------------------------------------------------------------------
# CLIENT FILES
# --------------------------------------------------------------------

# ---------------------------
# 1. client/src/App.js
# ---------------------------
cat << 'EOF' > client/src/App.js
import React, { useState } from "react";
import Sidebar from "./components/Sidebar";
import Chat from "./components/Chat";
import SearchCases from "./components/SearchCases";
import Notebook from "./components/Notebook";
import FactsAndUploads from "./components/FactsAndUploads";

/**
 * App.js - Main entry for the React client
 * Manages views and passes a currentProjectId to child components.
 */
function App() {
  // Example: tracking a single project ID for your "single-case" usage
  const [currentProjectId, setCurrentProjectId] = useState(null);

  // Which view is active? "chat", "search", "notebook", "facts", or other
  const [view, setView] = useState("chat");

  // Optionally, you could present a UI to create/select a project, then setCurrentProjectId(...)
  // For simplicity, we'll assume a project is already selected or hardcoded below:
  React.useEffect(() => {
    // In a real app, you'd fetch or create a project, e.g.:
    // setCurrentProjectId("64e8abc12345abcdef"); // example ID from your DB
  }, []);

  return (
    <div className="app-container">
      <Sidebar setView={setView} />
      <div className="main-content">
        {view === "chat" && <Chat currentProjectId={currentProjectId} />}
        {view === "search" && <SearchCases />}
        {view === "notebook" && <Notebook />}
        {view === "facts" && <FactsAndUploads currentProjectId={currentProjectId} />}
      </div>
    </div>
  );
}

export default App;
EOF

# ---------------------------
# 2. client/src/index.js
# ---------------------------
cat << 'EOF' > client/src/index.js
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./styles.css";

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# ---------------------------
# 3. client/src/styles.css
# ---------------------------
cat << 'EOF' > client/src/styles.css
.app-container {
  display: flex;
  height: 100vh;
  font-family: sans-serif;
  margin: 0;
  padding: 0;
}

.sidebar {
  width: 200px;
  background-color: #f8f8f8;
  border-right: 1px solid #ddd;
  padding: 1rem;
}

.sidebar button {
  display: block;
  margin-bottom: 0.5rem;
  width: 100%;
  padding: 0.5rem;
  cursor: pointer;
  border: 1px solid #ccc;
  background: #ffffff;
  text-align: left;
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 1rem;
  background-color: #fafafa;
}

/* Common container styling for each section */
.chat-container,
.search-cases-container,
.notebook-container,
.facts-uploads-container {
  flex: 1;
  border: 1px solid #ddd;
  padding: 1rem;
  border-radius: 6px;
  background-color: #ffffff;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
}

.chat-input {
  margin-top: 0.5rem;
  display: flex;
}

.chat-input input {
  flex: 1;
  padding: 0.5rem;
  margin-right: 0.5rem;
}

/* Example styling for SSE chunk tokens */
.token-stream {
  white-space: pre-wrap;
  background: #f1f1ff;
  padding: 0.5rem;
  border-radius: 4px;
  margin-top: 0.5rem;
  border: 1px solid #ddd;
}
EOF

# ---------------------------
# 4. client/src/components/Sidebar.jsx
# ---------------------------
cat << 'EOF' > client/src/components/Sidebar.jsx
import React from "react";

/**
 * Sidebar - Renders navigation buttons
 * setView is passed as a prop from App.js
 */
const Sidebar = ({ setView }) => {
  return (
    <div className="sidebar">
      <button onClick={() => setView("chat")}>Chat</button>
      <button onClick={() => setView("facts")}>Facts & Uploads</button>
      <button onClick={() => setView("search")}>Search Cases</button>
      <button onClick={() => setView("notebook")}>Notebook</button>
    </div>
  );
};

export default Sidebar;
EOF

# ---------------------------
# 5. client/src/components/Chat.jsx
# ---------------------------
cat << 'EOF' > client/src/components/Chat.jsx
import React, { useState } from "react";

/**
 * Chat - Non-streaming example
 * currentProjectId is passed from App.js for retrieval context
 */
const Chat = ({ currentProjectId }) => {
  const [messages, setMessages] = useState([]);
  const [inputValue, setInputValue] = useState("");

  const sendMessage = async () => {
    if (!inputValue.trim()) return;

    const userMessageObj = { sender: "user", text: inputValue };
    setMessages((prev) => [...prev, userMessageObj]);

    try {
      // Call the /api/chat endpoint
      const res = await fetch("http://localhost:3001/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          projectId: currentProjectId, // optional if strictly single-case
          userMessage: inputValue,
        }),
      });

      const data = await res.json();

      const aiMessageObj = {
        sender: "ai",
        text: data.response || "(No response received)",
      };
      setMessages((prev) => [...prev, aiMessageObj]);
    } catch (error) {
      console.error("Error calling chat endpoint:", error);
      const errorMsg = { sender: "ai", text: "Error: " + error.message };
      setMessages((prev) => [...prev, errorMsg]);
    }

    setInputValue("");
  };

  return (
    <div className="chat-container">
      <h2>Chat / Q&A</h2>
      <div style={{ flex: 1, overflow: "auto", marginBottom: "1rem" }}>
        {messages.map((msg, idx) => (
          <div key={idx} style={{ margin: "8px 0" }}>
            <strong>{msg.sender === "user" ? "User" : "AI"}:</strong> {msg.text}
          </div>
        ))}
      </div>
      <div className="chat-input">
        <input
          type="text"
          placeholder="Type your query..."
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
        />
        <button onClick={sendMessage}>Send</button>
      </div>
    </div>
  );
};

export default Chat;
EOF

# ---------------------------
# 6. client/src/components/SearchCases.jsx
# ---------------------------
cat << 'EOF' > client/src/components/SearchCases.jsx
import React, { useState } from "react";

/**
 * SearchCases - Simple example fetching external references from /api/cases
 */
const SearchCases = () => {
  const [cases, setCases] = useState([]);

  const handleSearch = async () => {
    try {
      const res = await fetch("http://localhost:3001/api/cases");
      const data = await res.json();
      setCases(data);
    } catch (error) {
      console.error("Error fetching cases:", error);
    }
  };

  return (
    <div className="search-cases-container">
      <h2>Search External Cases</h2>
      <button onClick={handleSearch}>Fetch Sample Cases</button>
      <ul style={{ marginTop: "1rem" }}>
        {cases.map((item, idx) => (
          <li key={idx} style={{ marginBottom: "1rem" }}>
            <strong>{item.caseTitle}</strong>
            <div>{item.docketNumber}</div>
            <em>{item.snippet}</em>
          </li>
        ))}
      </ul>
    </div>
  );
};

export default SearchCases;
EOF

# ---------------------------
# 7. client/src/components/Notebook.jsx
# ---------------------------
cat << 'EOF' > client/src/components/Notebook.jsx
import React from "react";

/**
 * Notebook - a placeholder to store user notes or references
 */
const Notebook = () => {
  return (
    <div className="notebook-container">
      <h2>Notebook</h2>
      <p>Take notes or store references for your single-court-case research here.</p>
      {/* You could add a form or editor to store persistent notes */}
    </div>
  );
};

export default Notebook;
EOF

# ---------------------------
# 8. client/src/components/FactsAndUploads.jsx
# ---------------------------
cat << 'EOF' > client/src/components/FactsAndUploads.jsx
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
EOF

# ---------------------------
# 9. client/src/utils/parseChunk.js
# ---------------------------
cat << 'EOF' > client/src/utils/parseChunk.js
/**
 * parseChunk(chunk: string) -> string[]
 * A helper to parse lines of text from SSE chunk data.
 * You can adapt it to your SSE format.
 */
export function parseChunk(chunk) {
  // Example: chunk might be something like:
  // "event: token\ndata: Hello\n\nevent: token\ndata: world\n\n"
  // This function splits it on double newlines and extracts data lines.

  const lines = chunk.split("\n\n").filter(Boolean); // split on double newline
  const tokens = [];

  for (const line of lines) {
    if (line.startsWith("data: ")) {
      const rawData = line.replace("data: ", "").trim();
      if (rawData && rawData !== "[DONE]") {
        tokens.push(rawData);
      }
    }
  }

  return tokens; // e.g., ["Hello", "world", ...]
}
EOF

echo "=== All files created successfully. ==="
echo "You can now install server dependencies with:"
echo "  cd server && npm install"
echo "And client dependencies with e.g. create-react-app or a separate package.json in client/ if needed."
echo "Done!"
