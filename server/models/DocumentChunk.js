const mongoose = require("mongoose");

const DocumentChunkSchema = new mongoose.Schema({
  documentId: { type: mongoose.Schema.Types.ObjectId, ref: "Document" },
  chunkIndex: Number,       // The index/order of this chunk in the original doc
  text: String,             // The text content of this chunk
  pineconeId: String,       // The vector ID in Pinecone (or another vector DB)
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("DocumentChunk", DocumentChunkSchema);
