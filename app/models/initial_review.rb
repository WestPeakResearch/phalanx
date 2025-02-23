class InitialReview < ApplicationRecord
  belongs_to :application
  broadcasts_to :application, inserts_by: :prepend

  # Enum for the review decision (no: 0, maybe: 1, yes: 2, pending: 3)
  enum :decision, [:no, :maybe, :yes, :pending]

  # Validations
  validates :decision, presence: true
  validates :reviewer, presence: true
  validates :application_id, presence: true

  after_commit :broadcast_application_update

  private

  def broadcast_application_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "applications",
      target: "application_#{application.id}",
      partial: "initial_reviews/application_row",
      locals: { application: application },
    )
  end
end
