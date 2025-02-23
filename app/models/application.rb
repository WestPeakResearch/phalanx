class Application < ApplicationRecord
  has_many :initial_reviews, dependent: :destroy

  def self.displayable_columns
    # Exclude common Rails columns that usually don't need to be displayed
    column_names - ["created_at", "updated_at", "id"]
  end

  def self.default_visible_columns
    # Show only specific columns by default
    ["first_name", "last_name", "faculty", "major", "grad_year", "resume"]
  end
end
