class UpdateScoringFields < ActiveRecord::Migration[8.0]
  def change
    change_table :scorings do |t|
      # Remove overall_score column as it's no longer needed
      t.remove :overall_score

      # Change score fields from integer to decimal with precision 3, scale 2
      # This allows scores from 1.00 to 5.00
      t.change :interest_score, :decimal, precision: 3, scale: 2
      t.change :alignment_score, :decimal, precision: 3, scale: 2
      t.change :polish_score, :decimal, precision: 3, scale: 2
    end
  end
end
