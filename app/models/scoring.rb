class Scoring < ApplicationRecord
  belongs_to :application
  belongs_to :user
  broadcasts_to :application, inserts_by: :prepend

  # Define score ranges
  SCORE_RANGE = 1..5

  # Validations
  validates :user_id, presence: true
  validates :application_id, presence: true
  validates :interest_score, inclusion: { in: SCORE_RANGE }, allow_nil: true
  validates :alignment_score, inclusion: { in: SCORE_RANGE }, allow_nil: true
  validates :polish_score, inclusion: { in: SCORE_RANGE }, allow_nil: true
  validates :overall_score, inclusion: { in: SCORE_RANGE }, allow_nil: true
  validates :status, presence: true

  # Enum for the scoring status (pending: 0, completed: 1)
  enum :status, [:pending, :completed]

  before_save :calculate_overall_score
  after_commit :broadcast_application_update, on: [:create, :update, :destroy]

  # Calculate the average score across the three main criteria
  def average_score
    scores = [interest_score, alignment_score, polish_score].compact
    return nil if scores.empty?

    (scores.sum.to_f / scores.size).round(1)
  end

  def previously_completed?
    status_previously_was == "completed"
  end

  private

  # Calculate the overall score as the average of the three main scores
  def calculate_overall_score
    if status == "completed" && interest_score.present? && alignment_score.present? && polish_score.present?
      self.overall_score = ((interest_score + alignment_score + polish_score) / 3.0).round(1)
    end
  end

  def broadcast_application_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "scoring_applications",
      target: "scoring_application_#{application.id}",
      partial: "scorings/application_row",
      locals: { application: application },
    )
  end

  def broadcast_update
    application.broadcast_replace_later
  end
end
