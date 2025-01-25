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
