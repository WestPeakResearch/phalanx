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
        description: "View all applications",
        path: applications_path,
        icon: "list_alt",
      },
      {
        name: "Initial Review",
        description: "Quick filter to screen out applications",
        path: initial_reviews_path,
        icon: "rate_review",
      },
      {
        name: "Scoring",
        description: "Score applications in detail",
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
