const express = require("express");
const router = express.Router();

/**
 * GET /api/cases
 * Example: returns mock or external references for relevant case law
 */
router.get("/", (req, res) => {
  const sampleCases = [
    {
      caseTitle: "Robinson v. De Niro",
      docketNumber: "1:19-cv-09156 (S.D.N.Y., Jul 8, 2021)",
      snippet: "Discusses 'faithless servant doctrine' in detail...",
    },
    {
      caseTitle: "Doe v. ExampleCorp",
      docketNumber: "2:21-cv-04234 (C.D.Cal., Jan 15, 2022)",
      snippet: "Addresses breach of fiduciary duty under California law...",
    }
  ];
  res.json(sampleCases);
});

module.exports = router;
