class InitialReview < ApplicationRecord
  belongs_to :application
  belongs_to :user

  # Remove the default broadcast as we'll handle it manually
  # broadcasts_to :application, inserts_by: :prepend

  # Enum for the review decision (no: 0, maybe: 1, yes: 2, pending: 3)
  enum :decision, [:no, :maybe, :yes, :pending]

  # Validations
  validates :decision, presence: true
  validates :user_id, presence: true
  validates :application_id, presence: true

  after_commit :broadcast_application_update
  after_commit :broadcast_user_pending_reviews_update

  private

  def broadcast_application_update
    # Broadcast to the applications channel for the application row update
    Turbo::StreamsChannel.broadcast_replace_to(
      "applications",
      target: "application_#{application.id}",
      partial: "initial_reviews/application_row",
      locals: { application: application },
    )
  end

  def broadcast_user_pending_reviews_update
    # Broadcast to the specific user's pending reviews channel for the button update
    Turbo::StreamsChannel.broadcast_update_to(
      "user_#{user_id}_pending_reviews",
      target: "review_button_container",
      partial: "initial_reviews/review_button",
      locals: { current_user: user },
    )
  end
end
