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
