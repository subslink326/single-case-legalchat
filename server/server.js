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
