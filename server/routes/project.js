const express = require("express");
const router = express.Router();
const Project = require("../models/Project");

// Create a new Project (single-case)
router.post("/", async (req, res) => {
  try {
    const { title, docketNumber, description } = req.body;
    const project = await Project.create({ title, docketNumber, description });
    res.json(project);
  } catch (err) {
    console.error("Error creating project:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get an existing Project by ID
router.get("/:projectId", async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    if (!project) {
      return res.status(404).json({ error: "Project not found." });
    }
    res.json(project);
  } catch (err) {
    console.error("Error fetching project:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
