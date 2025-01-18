# single-case-legalchat


# **Single-Case LegalChat**

**Single-Case LegalChat** is an AI-powered web application designed to help attorneys, paralegals, or legal researchers work on a **single court case** at a time. The system integrates:

- **Document Management**: Upload and categorize case documents (discovery, transcripts, communications, etc.).  
- **Retrieval-Augmented Generation (RAG)**: Automatically retrieve relevant chunks from uploaded documents to contextualize GPT-4 responses.  
- **AI Chat Interface**: Ask questions about the case, receive context-aware answers.  
- **Real-Time Streaming (Optional)**: Stream partial token responses from the GPT-4 model for a smoother user experience.  
- **External Case Links**: Fetch references to new case law or external links without copying entire documents into the system.

---

## **Table of Contents**

1. [Key Features](#key-features)  
2. [Tech Stack](#tech-stack)  
3. [Project Structure](#project-structure)  
4. [Installation & Setup](#installation--setup)  
5. [Environment Variables](#environment-variables)  
6. [Running the App](#running-the-app)  
7. [Usage Guide](#usage-guide)  
8. [Additional Notes](#additional-notes)

---

## **Key Features**

1. **Single-Case Focus**  
   - Keep all documents, chat history, and references scoped to a single litigation matter.

2. **Document Upload & Management**  
   - Upload PDF/Word text (currently text copy-paste) to the system.  
   - Store them in MongoDB (metadata) and a vector DB (embeddings) for quick retrieval.

3. **Retrieval-Augmented GPT-4**  
   - Automatically find relevant document chunks to include in GPT-4 prompts.  
   - Ask nuanced questions about the case, get references to document snippets.

4. **Chat Interface**  
   - Simple Q&A chat system.  
   - Optional streaming of answers (SSE or WebSockets).

5. **External Case Lookup**  
   - Basic “Search Cases” feature for referencing external legal databases.  
   - Returns links instead of full text so you can selectively incorporate them.

6. **Project-Based Storage**  
   - Store documents, chat logs, and other data in MongoDB.  
   - Each project can represent a unique “single case.”

---

## **Tech Stack**

- **Frontend**  
  - [React](https://reactjs.org/) (Create React App structure)  
  - JavaScript/JSX  
  - Basic CSS styling

- **Backend**  
  - [Node.js](https://nodejs.org/) + [Express](https://expressjs.com/)  
  - [Mongoose](https://mongoosejs.com/) for MongoDB  
  - [OpenAI API](https://platform.openai.com/docs/introduction) for GPT-4 embeddings and chat  
  - [Pinecone](https://www.pinecone.io/) (or another vector DB) for semantic search  
  - [dotenv](https://www.npmjs.com/package/dotenv) for environment variable management

---

## **Project Structure**

Below is a high-level overview of the repo:

```
my-legalchat-project/
├── package.json          // Root-level scripts to run client & server concurrently
├── README.md             // This file
│
├── client/               // React frontend
│   ├── package.json
│   ├── public/
│   └── src/
│       ├── App.js
│       ├── index.js
│       ├── styles.css
│       ├── components/
│       │   ├── Sidebar.jsx
│       │   ├── Chat.jsx
│       │   ├── SearchCases.jsx
│       │   ├── Notebook.jsx
│       │   └── FactsAndUploads.jsx
│       └── utils/
│           └── parseChunk.js
│
└── server/               // Node/Express backend
    ├── package.json
    ├── .env              // Environment variables (not committed)
    ├── server.js
    ├── config/
    │   └── database.js
    ├── pinecone.js
    ├── models/
    │   ├── Project.js
    │   ├── Document.js
    │   ├── DocumentChunk.js
    │   └── ChatMessage.js
    ├── routes/
    │   ├── project.js
    │   ├── upload.js
    │   ├── chat.js
    │   └── cases.js
    └── utils/
        ├── embeddings.js
        ├── chunker.js
        └── retrieval.js
```

---

## **Installation & Setup**

1. **Clone the Repository**  
   ```bash
   git clone https://github.com/your-username/my-legalchat-project.git
   cd my-legalchat-project
   ```

2. **Install Dependencies**  
   - **Root-level** (optional if you have a monorepo setup):  
     ```bash
     npm run install-all
     ```
     or manually install in both `client/` and `server/`:

   - **Frontend**:  
     ```bash
     cd client
     npm install
     ```
   - **Backend**:  
     ```bash
     cd ../server
     npm install
     ```

3. **Create & Configure `.env`**  
   - In `server/.env`, set your environment variables (see [Environment Variables](#environment-variables)).  
   - Ensure you do **not** commit `.env` to version control.

---

## **Environment Variables**

In `server/.env` (local dev) or in your hosting environment (e.g., Replit Secrets, Heroku Config Vars, etc.):

```bash
OPENAI_API_KEY=sk-xxxx
MONGO_URI=mongodb+srv://username:password@cluster0.mongodb.net/yourDB
PINECONE_API_KEY=your-pinecone-api-key
PINECONE_ENV=your-pinecone-environment  # e.g. "us-west1-gcp"
PORT=3001  # optional
```

Other variables as needed.

---

## **Running the App**

### **Option A: Run Separately**

- **Backend** (Express Server):
  ```bash
  cd server
  npm start
  ```
  This will start your server at `http://localhost:3001/` (by default).

- **Frontend** (React Client):
  ```bash
  cd client
  npm start
  ```
  This will start the React development server at `http://localhost:3000/`.

### **Option B: Concurrently (Root-Level)**

If you have a **root-level** `package.json` that uses **concurrently**:

```json
{
  "scripts": {
    "start": "concurrently \"npm run start-server\" \"npm run start-client\"",
    "start-server": "cd server && npm start",
    "start-client": "cd client && npm start",
    "install-all": "cd client && npm install && cd ../server && npm install"
  }
}
```

Then just run:

```bash
npm run start
```

Which spins up both **React** (http://localhost:3000) and **Express** (http://localhost:3001).

---

## **Usage Guide**

1. **Access the App**: Open `http://localhost:3000` in your browser.  
2. **Upload Documents**: Navigate to **Facts & Uploads** (via the sidebar), paste in text from a file (e.g., a motion, transcript).  
   - Assign a **category** (discovery, transcript, etc.).  
   - The system stores the text in MongoDB and upserts chunk embeddings into Pinecone.  
3. **Ask Questions**: Go to **Chat**.  
   - Type your query (e.g., “What does the transcript say about expert witness deadlines?”).  
   - The system retrieves relevant chunks and sends them as context to GPT-4, providing a targeted answer.  
4. **Search External Cases**: Go to **Search Cases**.  
   - Fetch sample or real external references (links) to new case law.  
   - Download or incorporate as needed.  
5. **Notebook**: Jot down notes or references for your single-case matter. (Currently a stub—could be expanded to store notes in MongoDB.)

---

## **Additional Notes**

- **Streaming**: If you’d like partial token streaming, you can adapt the `/api/chat` route to use Server-Sent Events (SSE) or WebSockets, and the client to parse tokens incrementally (`parseChunk.js`).  
- **PDF/Word Extraction**: In production, you’d likely integrate a file upload mechanism (`multer`) and a parser to extract text from PDFs or Word docs automatically.  
- **Security**: This project is a prototype. For real legal workflows, you’ll need SSL/TLS, user authentication/authorization, and more robust permissions.  
- **Large Data**: For very large sets of documents, carefully manage chunking size and token usage, and be mindful of costs (OpenAI GPT-4).  
- **Collaboration**: Each instance or “Project” is intended for a single case. If you add multi-user collaboration, consider role-based access control.  

Enjoy exploring **Single-Case LegalChat**—a more efficient way to handle discovery, transcripts, and real-time AI assistance for your active litigation matter!
