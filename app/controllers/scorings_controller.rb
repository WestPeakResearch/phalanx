class ScoringsController < ApplicationController
  def index
    @applications = Application.includes(:scorings)
      .where.not(year: nil)
      .order(:last_name, :first_name) # Sort alphabetically by last name, then first name
      .to_a  # Force evaluation of the query
  end

  def assign_reviewers
    reviewers_per_year = 2

    reviewer_ids = params[:reviewer_ids]&.map(&:to_i) || []
    if reviewer_ids.empty?
      redirect_to scorings_path, alert: "Please select at least one reviewer"
      return
    end

    applications = Application.where.not(year: nil).group_by do |app|
      app.year >= 4 ? 4 : app.year
    end

    reviewers = User.where(id: reviewer_ids).order(:name).to_a
    year_levels = [1, 2, 3, 4] # 4 represents both year 4 and 5
    assignments = Hash.new { |h, k| h[k] = [] }

    if reviewers.size < year_levels.size * reviewers_per_year
      if reviewers.size < reviewers_per_year
        redirect_to scorings_path,
          alert: "Not enough reviewers. Need at least #{reviewers_per_year} reviewers to assign #{reviewers_per_year} per year level."
        return
      end

      year_levels.each do |year|
        2.times do
          reviewer = reviewers.first
          if assignments[year].include?(reviewer)
            reviewers.rotate!
            reviewer = reviewers.first
          end
          assignments[year] << reviewer
          reviewers.rotate!
        end
      end
    else
      reviewers.each do |reviewer|
        year_levels.each do |year|
          assignments[year] << reviewer
        end
      end
    end

    assignments.each do |year, year_reviewers|
      apps = if year == 4
          applications[4].to_a + (applications[5] || []).to_a
        else
          applications[year].to_a
        end

      next if apps.empty?

      year_reviewers.each do |reviewer|
        apps.each do |app|
          next if app.scorings.exists?(user: reviewer)

          app.scorings.create!(
            user: reviewer,
            status: :pending,
          )
        end
      end
    end

    summary = assignments.map do |year, reviewers|
      year_text = year == 4 ? "Years 4 & 5" : "Year #{year}"
      "#{year_text}: #{reviewers.map(&:name).join(", ")}"
    end.join("\n")

    redirect_to scorings_path, notice: "Reviewers assigned successfully!\n\n#{summary}"
  end

  def review_one
    # Find the next pending scoring assigned to the current user
    scoring = Scoring.includes(:application)
      .where(user: current_user, status: :pending)
      .joins(:application)
      .where.not(applications: { year: nil })
      .first

    if scoring
      redirect_to review_scoring_path(scoring.application)
    else
      redirect_to scorings_path, notice: "No pending reviews assigned to you."
    end
  end

  def review
    @application = Application.includes(:scorings).find(params[:id])
    @scoring = @application.scorings.find_by(user: current_user)
    @is_editing = @scoring&.completed?

    if @scoring.nil?
      redirect_to create_pending_scoring_path(@application, from_index: params[:from_index])
    end
  end

  def create_pending
    @application = Application.includes(:scorings).find(params[:id])
    existing_scoring = @application.scorings.find_by(user: current_user)

    if existing_scoring
      redirect_to review_scoring_path(@application, from_index: params[:from_index])
      return
    end

    @scoring = @application.scorings.create!(
      status: :pending,
      user: current_user,
    )
    # Broadcast the update after creating pending scoring
    Turbo::StreamsChannel.broadcast_replace_to(
      "scoring_applications",
      target: "scoring_application_#{@application.id}",
      partial: "scorings/application_row",
      locals: { application: @application },
    )
    redirect_to review_scoring_path(@application, from_index: params[:from_index])
  end

  def submit
    @application = Application.find(params[:id])
    scoring = @application.scorings.find_by(user: current_user)

    unless scoring
      redirect_to scorings_path, alert: "No scoring found"
      return
    end

    if params[:skip]
      cleanup(@application)
      recede_or_redirect_to scorings_path, notice: "Skipped scoring"
    else
      # Update the scoring with the submitted values
      scoring_params = params.permit(
        :interest_score,
        :alignment_score,
        :polish_score,
        :comments
      ).merge(status: :completed)

      if scoring.update(scoring_params)
        if params[:from_index]
          recede_or_redirect_to scorings_path, notice: scoring.previously_completed? ? "Scoring updated successfully" : "Scoring submitted successfully"
        else
          redirect_to review_one_scorings_path, notice: scoring.previously_completed? ? "Scoring updated successfully" : "Scoring submitted successfully"
        end
      else
        redirect_to review_scoring_path(@application), alert: "Error submitting scoring: #{scoring.errors.full_messages.join(", ")}"
      end
    end
  end

  def cleanup(application)
    pending_scoring = application.scorings.find_by(user: current_user, status: :pending)

    if pending_scoring
      pending_scoring.destroy
      # Broadcast the update after destroying
      Turbo::StreamsChannel.broadcast_replace_to(
        "scoring_applications",
        target: "scoring_application_#{application.id}",
        partial: "scorings/application_row",
        locals: { application: application },
      )
    end
  end
end
