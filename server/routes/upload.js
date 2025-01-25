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
