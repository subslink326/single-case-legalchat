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
