class BackfillSelectedForInterview < ActiveRecord::Migration[8.0]
  def up
    # Update all existing records to have selected_for_interview set to false
    execute <<-SQL
      UPDATE applications 
      SET selected_for_interview = false 
      WHERE selected_for_interview IS NULL
    SQL
  end

  def down
    # No need for down migration as this is just setting default values
  end
end
