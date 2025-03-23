class InterviewSelectionsController < ApplicationController
  def index
    @applications_by_year = Application.includes(scorings: :user)
      .where.not(year: nil)
      .joins(:scorings)
      .where(scorings: { status: :completed })
      .group("applications.id")
      .select("applications.*, AVG(scorings.overall_score) as avg_score")
      .group_by(&:year)
      .transform_values { |apps| apps.sort_by(&:avg_score).reverse }
  end

  def details
    @application = Application.includes(scorings: :user).find(params[:id])
    render partial: "details", layout: false
  end
end
