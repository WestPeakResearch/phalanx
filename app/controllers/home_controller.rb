class HomeController < ApplicationController
  def index
    @stages = [
      {
        name: "Applications Overview",
        description: "View and manage all applications",
        path: applications_path,
        icon: "fas fa-list",
      },
      {
        name: "Initial Review",
        description: "First round of application reviews",
        path: initial_reviews_path,
        icon: "fas fa-check-double",
      },
    ]
  end
end
