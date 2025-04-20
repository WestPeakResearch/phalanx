class InitialReviewsController < ApplicationController
  def index
    @applications = Application.includes(:initial_reviews)
      .where.not(year: nil)
      .order(:last_name, :first_name) # Sort alphabetically by last name, then first name
      .to_a  # Force evaluation of the query

    # Calculate applications needing reviews
    @applications_needing_reviews = @applications.select do |app|
      app.initial_reviews.count < 2
    end

    # Calculate total number of reviews needed
    @total_reviews_needed = @applications_needing_reviews.sum do |app|
      2 - app.initial_reviews.count
    end
  end

  def assign
    @reviewers = User.all  # You might want to filter this based on roles

    # Debug output to help us troubleshoot
    Rails.logger.info "ASSIGN METHOD CALLED: #{request.method}"

    if request.post?
      selected_reviewer_ids = params[:reviewer_ids] || []
      selected_reviewers = User.where(id: selected_reviewer_ids)

      # Get applications needing reviews
      applications = Application.includes(:initial_reviews)
        .where.not(year: nil)
        .having("COUNT(initial_reviews.id) < 2")
        .left_joins(:initial_reviews)
        .group("applications.id")

      assignments = assign_reviews(applications, selected_reviewers)

      # Perform the assignments in a transaction
      ActiveRecord::Base.transaction do
        assignments.each do |application, reviewer|
          application.initial_reviews.create!(
            decision: :pending,
            user: reviewer,
          )
        end
      end

      redirect_to initial_reviews_path,
                  notice: "Successfully assigned #{assignments.count} reviews to #{selected_reviewers.count} reviewers"
    end
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
      redirect_to review_application_path(application)
    else
      render :all_reviewed
    end
  end

  def review
    @application = Application.includes(:initial_reviews).find(params[:id])
    @pending_review = @application.initial_reviews.find_by(user: current_user, decision: :pending)

    unless @pending_review
      # Check if there are other pending reviews for this user
      next_pending_review = InitialReview.where(user: current_user, decision: :pending).first

      if next_pending_review
        # Redirect to the next pending application
        redirect_to review_application_path(next_pending_review.application)
      else
        # Create a pending review for this application
        redirect_to create_pending_initial_review_path(@application, from_index: params[:from_index])
      end
    end
  end

  def create_pending
    @application = Application.includes(:initial_reviews).find(params[:id])

    # Check if a user_id is provided (for admin assignment)
    assigned_user_id = params[:user_id].present? ? params[:user_id] : current_user.id
    assigned_user = User.find(assigned_user_id)

    # Check if the assigned user already has a review for this application
    existing_review = @application.initial_reviews.find_by(user: assigned_user)

    if existing_review
      # Update the existing review to pending
      existing_review.update!(decision: :pending)
      @pending_review = existing_review
      redirect_to review_application_path(@application, from_index: params[:from_index], editing: true)
    else
      # Create a new review if none exists
      @pending_review = @application.initial_reviews.create!(
        decision: :pending,
        user: assigned_user,
      )
      redirect_to review_application_path(@application, from_index: params[:from_index])
    end

    # The after_commit callbacks in the model will handle all the broadcasting
    # - broadcast_application_update will update the application row
    # - broadcast_user_pending_reviews_update will update the button
    broadcast_batch_assign_update
  end

  def submit
    @application = Application.find(params[:id])
    review = @application.initial_reviews.find_by(user: current_user, decision: :pending)

    unless review
      redirect_to initial_reviews_path, alert: "No pending review found"
      return
    end

    if params[:skip]
      cleanup(@application)
      recede_or_redirect_to initial_reviews_path, notice: "Skipped review"
    elsif params[:decision].present?
      if review.update(decision: params[:decision])
        # The after_commit callback will handle the broadcast
        broadcast_batch_assign_update

        # Check if there are other pending reviews for this user
        next_pending_review = InitialReview.where(user: current_user, decision: :pending).first

        if next_pending_review && !params[:from_index]
          # Redirect to the next pending application
          redirect_to review_application_path(next_pending_review.application), notice: "Review submitted successfully"
        else
          # No more pending reviews, go back to index
          recede_or_redirect_to initial_reviews_path, notice: "Review submitted successfully"
        end
      else
        redirect_to review_application_path(@application), alert: "Error submitting review"
      end
    else
      # Just going back to index, keep the pending review
      recede_or_redirect_to initial_reviews_path
    end
  end

  private

  def assign_reviews(applications, selected_reviewers)
    # Track assignments per reviewer
    reviewer_assignments = Hash.new(0)

    # Get applications needing reviews (less than 2 reviews)
    applications_needing_reviews = applications.select do |app|
      app.initial_reviews.count < 2
    end

    # Sort applications by number of existing reviews (ascending)
    # This ensures applications with 0 reviews get priority
    applications_needing_reviews.sort_by! { |app| app.initial_reviews.count }

    assignments = []

    applications_needing_reviews.each do |application|
      # Calculate how many reviewers we need for this application
      needed_reviewers = 2 - application.initial_reviews.count

      # Get reviewers who haven't reviewed this application yet
      available_reviewers = selected_reviewers.reject do |reviewer|
        application.initial_reviews.exists?(user: reviewer)
      end

      next if available_reviewers.count < needed_reviewers

      # Find the reviewers with least assignments
      needed_reviewers.times do
        # Find reviewer with least assignments from available reviewers
        reviewer = available_reviewers.min_by { |r| reviewer_assignments[r.id] }

        # Record the assignment
        assignments << [application, reviewer]
        reviewer_assignments[reviewer.id] += 1

        # Remove this reviewer from available reviewers for this application
        available_reviewers.delete(reviewer)
      end
    end

    assignments
  end

  def cleanup(application)
    pending_review = application.initial_reviews.find_by(user: current_user, decision: :pending)

    if pending_review
      pending_review.destroy
      # The after_commit callbacks in the model will handle all the broadcasting
      broadcast_batch_assign_update
    end
  end

  def broadcast_batch_assign_update
    # Recalculate the counts
    applications = Application.includes(:initial_reviews)
      .where.not(year: nil)
      .to_a

    @applications_needing_reviews = applications.select do |app|
      app.initial_reviews.count < 2
    end

    @total_reviews_needed = @applications_needing_reviews.sum do |app|
      2 - app.initial_reviews.count
    end

    # Broadcast the update
    Turbo::StreamsChannel.broadcast_replace_to(
      "applications",
      target: "batch_assign_section",
      partial: "initial_reviews/batch_assign_section",
      locals: {
        applications_needing_reviews: @applications_needing_reviews,
        total_reviews_needed: @total_reviews_needed,
      },
    )
  end
end
