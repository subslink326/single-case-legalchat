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
