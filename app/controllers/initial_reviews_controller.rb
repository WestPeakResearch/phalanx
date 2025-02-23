class InitialReviewsController < ApplicationController
  def index
    @applications = Application.includes(:initial_reviews)
      .where.not(year: nil)
      .order(:year)
      .to_a  # Force evaluation of the query
  end

  def review_one
    # Find application with less than 2 reviews
    application = Application.includes(:initial_reviews)
      .where.not(year: nil)
      .having("COUNT(initial_reviews.id) < 2")
      .left_joins(:initial_reviews)
      .group("applications.id")
      .first

    if application
      # Create pending review immediately
      application.initial_reviews.create!(
        decision: :pending,
        reviewer: "TEMP_USER",
      )
      redirect_to review_application_path(application)
    else
      render :all_reviewed
    end
  end

  def review
    @application = Application.includes(:initial_reviews).find(params[:id])
    @pending_review = @application.initial_reviews.find_by(reviewer: "TEMP_USER", decision: :pending)

    unless @pending_review
      redirect_to initial_reviews_path, alert: "No pending review found"
    end
  end

  def submit
    @application = Application.find(params[:id])
    review = @application.initial_reviews.find_by(reviewer: "TEMP_USER", decision: :pending)

    unless review
      redirect_to initial_reviews_path, alert: "No pending review found"
      return
    end

    if params[:skip]
      review.destroy
      # Broadcast the update after destroying
      Turbo::StreamsChannel.broadcast_replace_to(
        "applications",
        target: "application_#{@application.id}",
        partial: "initial_reviews/application_row",
        locals: { application: @application },
      )
      redirect_to review_one_initial_reviews_path, notice: "Skipped review"
    else
      if review.update(decision: params[:decision])
        # The after_commit callback will handle the broadcast
        redirect_to review_one_initial_reviews_path, notice: "Review submitted successfully"
      else
        redirect_to review_application_path(@application), alert: "Error submitting review"
      end
    end
  end
end
