import React from "react";

/**
 * Sidebar - Renders navigation buttons
 * setView is passed as a prop from App.js
 */
const Sidebar = ({ setView }) => {
  return (
    <div className="sidebar">
      <button onClick={() => setView("chat")}>Chat</button>
      <button onClick={() => setView("facts")}>Facts & Uploads</button>
      <button onClick={() => setView("search")}>Search Cases</button>
      <button onClick={() => setView("notebook")}>Notebook</button>
    </div>
  );
};

export default Sidebar;
