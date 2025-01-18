const mongoose = require("mongoose");

const ProjectSchema = new mongoose.Schema({
  title: String,           // e.g., "Smith v. Doe"
  docketNumber: String,    // e.g., "1:23-cv-456"
  description: String,     // Optional summary/description of this case
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Project", ProjectSchema);
