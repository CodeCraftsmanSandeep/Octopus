// Dummy data for repositories
const repositories = [
    {
      name: "Root",
      type: "folder",
      children: [
        {
          name: "Project1",
          type: "folder",
          children: [
            {
              name: "File1",
              type: "file"
            },
            {
              name: "File2",
              type: "file"
            }
          ]
        },
        {
          name: "Project2",
          type: "folder",
          children: [
            {
              name: "File3",
              type: "file"
            }
          ]
        }
      ]
    }
  ];
  
  // Function to create a tree-like structure
  function createTree(parentElement, data) {
    const ul = document.createElement("ul");
    parentElement.appendChild(ul);
  
    data.forEach(item => {
      const li = document.createElement("li");
      ul.appendChild(li);
  
      const icon = document.createElement("i");
      icon.className = item.type === "folder" ? "fas fa-folder" : "fas fa-file";
      li.appendChild(icon);
  
      const text = document.createTextNode(item.name);
      li.appendChild(text);
  
      if (item.type === "folder") {
        li.classList.add("folder");
        createTree(li, item.children);
      }
    });
  }
  
  // Function to toggle folder visibility
  function toggleFolder(event) {
    if (event.target.tagName === "I") {
      event.target.parentElement.querySelector("ul").classList.toggle("collapsed");
    }
  }
  
  document.addEventListener("DOMContentLoaded", function() {
    // Find the button to view repositories
    const viewRepositoriesButton = document.querySelector(".view-repositories");
  
    // Add event listener to the button
    viewRepositoriesButton.addEventListener("click", function() {
      // Create a container for the repository tree
      const repositoryContainer = document.createElement("div");
      repositoryContainer.classList.add("repository-container");
  
      // Create the repository tree
      createTree(repositoryContainer, repositories);
  
      // Append the repository tree to the body
      document.body.appendChild(repositoryContainer);
  
      // Add event listener to toggle folder visibility
      repositoryContainer.addEventListener("click", toggleFolder);
    });
  });
  