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
      {
        name: "Scoring",
        description: "Score applications based on detailed criteria",
        path: scorings_path,
        icon: "grade",
      },
      {
        name: "Interview Selection",
        description: "Select candidates for interviews based on average scores",
        path: interview_selections_path,
        icon: "people",
      },
    ]
  end
end
