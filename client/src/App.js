import React, { useState } from "react";
import Sidebar from "./components/Sidebar";
import Chat from "./components/Chat";
import SearchCases from "./components/SearchCases";
import Notebook from "./components/Notebook";
import FactsAndUploads from "./components/FactsAndUploads";

/**
 * App.js - Main entry for the React client
 * Manages views and passes a currentProjectId to child components.
 */
function App() {
  // Example: tracking a single project ID for your "single-case" usage
  const [currentProjectId, setCurrentProjectId] = useState(null);

  // Which view is active? "chat", "search", "notebook", "facts", or other
  const [view, setView] = useState("chat");

  // Optionally, you could present a UI to create/select a project, then setCurrentProjectId(...)
  // For simplicity, we'll assume a project is already selected or hardcoded below:
  React.useEffect(() => {
    // In a real app, you'd fetch or create a project, e.g.:
    // setCurrentProjectId("64e8abc12345abcdef"); // example ID from your DB
  }, []);

  return (
    <div className="app-container">
      <Sidebar setView={setView} />
      <div className="main-content">
        {view === "chat" && <Chat currentProjectId={currentProjectId} />}
        {view === "search" && <SearchCases />}
        {view === "notebook" && <Notebook />}
        {view === "facts" && <FactsAndUploads currentProjectId={currentProjectId} />}
      </div>
    </div>
  );
}

export default App;
