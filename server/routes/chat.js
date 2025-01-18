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
