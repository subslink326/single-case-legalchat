import React, { useState } from "react";

/**
 * Chat - Non-streaming example
 * currentProjectId is passed from App.js for retrieval context
 */
const Chat = ({ currentProjectId }) => {
  const [messages, setMessages] = useState([]);
  const [inputValue, setInputValue] = useState("");

  const sendMessage = async () => {
    if (!inputValue.trim()) return;

    const userMessageObj = { sender: "user", text: inputValue };
    setMessages((prev) => [...prev, userMessageObj]);

    try {
      // Call the /api/chat endpoint
      const res = await fetch("http://localhost:3001/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          projectId: currentProjectId, // optional if strictly single-case
          userMessage: inputValue,
        }),
      });

      const data = await res.json();

      const aiMessageObj = {
        sender: "ai",
        text: data.response || "(No response received)",
      };
      setMessages((prev) => [...prev, aiMessageObj]);
    } catch (error) {
      console.error("Error calling chat endpoint:", error);
      const errorMsg = { sender: "ai", text: "Error: " + error.message };
      setMessages((prev) => [...prev, errorMsg]);
    }

    setInputValue("");
  };

  return (
    <div className="chat-container">
      <h2>Chat / Q&A</h2>
      <div style={{ flex: 1, overflow: "auto", marginBottom: "1rem" }}>
        {messages.map((msg, idx) => (
          <div key={idx} style={{ margin: "8px 0" }}>
            <strong>{msg.sender === "user" ? "User" : "AI"}:</strong> {msg.text}
          </div>
        ))}
      </div>
      <div className="chat-input">
        <input
          type="text"
          placeholder="Type your query..."
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
        />
        <button onClick={sendMessage}>Send</button>
      </div>
    </div>
  );
};

export default Chat;
