const mongoose = require("mongoose");

const ChatMessageSchema = new mongoose.Schema({
  projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project" },
  sender: { type: String, enum: ["user", "ai"] },
  text: String,
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("ChatMessage", ChatMessageSchema);
