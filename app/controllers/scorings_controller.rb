class ScoringsController < ApplicationController
  def index
    @applications = Application.includes(:scorings)
      .where.not(year: nil)
      .order(:last_name, :first_name) # Sort alphabetically by last name, then first name
      .to_a  # Force evaluation of the query
  end

  def review_one
    # Find application with less than 2 scorings
    application = Application.includes(:scorings)
      .where.not(year: nil)
      .having("COUNT(scorings.id) < 2")
      .left_joins(:scorings)
      .group("applications.id")
      .first

    if application
      redirect_to review_scoring_path(application)
    else
      render :all_scored
    end
  end

  def review
    @application = Application.includes(:scorings).find(params[:id])
    @pending_scoring = @application.scorings.find_by(user: current_user, status: :pending)

    unless @pending_scoring
      redirect_to create_pending_scoring_path(@application, from_index: params[:from_index])
    end
  end

  def create_pending
    @application = Application.includes(:scorings).find(params[:id])
    @pending_scoring = @application.scorings.create!(
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
    scoring = @application.scorings.find_by(user: current_user, status: :pending)

    unless scoring
      redirect_to scorings_path, alert: "No pending scoring found"
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
        # The after_commit callback will handle the broadcast
        if params[:from_index]
          recede_or_redirect_to scorings_path, notice: "Scoring submitted successfully"
        else
          redirect_to review_one_scorings_path, notice: "Scoring submitted successfully"
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
