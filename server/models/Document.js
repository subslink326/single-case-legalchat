const mongoose = require("mongoose");

const DocumentSchema = new mongoose.Schema({
  projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project" },
  fileName: String,                       // Original file name or user-given title
  category: {
    type: String,
    enum: ["discovery", "transcript", "communication", "motion", "other"],
    default: "other"
  },
  content: String,                        // Extracted text content (if stored)
  uploadedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Document", DocumentSchema);
