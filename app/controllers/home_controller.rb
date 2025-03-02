class HomeController < ApplicationController
  def index
    @stages = [
      {
        name: "Documents",
        description: "Manage documents: upload, export, and reset application data",
        path: new_document_path,
        icon: "description",
      },
      {
        name: "Applications Overview",
        description: "View and manage all applications",
        path: applications_path,
        icon: "list_alt",
      },
      {
        name: "Initial Review",
        description: "First round of application reviews",
        path: initial_reviews_path,
        icon: "rate_review",
      },
    ]
  end
end
