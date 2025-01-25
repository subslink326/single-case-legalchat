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
