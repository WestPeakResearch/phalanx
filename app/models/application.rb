class Application < ApplicationRecord
  has_many :initial_reviews, dependent: :destroy
  has_many :scorings, dependent: :destroy

  def self.displayable_columns
    # Exclude common Rails columns that usually don't need to be displayed
    column_names - ["created_at", "updated_at", "id"]
  end

  def self.default_visible_columns
    # Show only specific columns by default
    ["first_name", "last_name", "faculty", "major", "grad_year", "resume"]
  end

  # Calculate overall score across all completed scorings
  def overall_score
    completed_scorings = scorings.select(&:completed?)
    return nil if completed_scorings.empty?

    avg_scores = completed_scorings.map(&:average_score).compact
    return nil if avg_scores.empty?

    (avg_scores.sum / avg_scores.size).round(2)
  end

  # Alias for backward compatibility with existing code
  alias_method :avg_score, :overall_score
end
