import React, { useState } from "react";

/**
 * SearchCases - Simple example fetching external references from /api/cases
 */
const SearchCases = () => {
  const [cases, setCases] = useState([]);

  const handleSearch = async () => {
    try {
      const res = await fetch("http://localhost:3001/api/cases");
      const data = await res.json();
      setCases(data);
    } catch (error) {
      console.error("Error fetching cases:", error);
    }
  };

  return (
    <div className="search-cases-container">
      <h2>Search External Cases</h2>
      <button onClick={handleSearch}>Fetch Sample Cases</button>
      <ul style={{ marginTop: "1rem" }}>
        {cases.map((item, idx) => (
          <li key={idx} style={{ marginBottom: "1rem" }}>
            <strong>{item.caseTitle}</strong>
            <div>{item.docketNumber}</div>
            <em>{item.snippet}</em>
          </li>
        ))}
      </ul>
    </div>
  );
};

export default SearchCases;
