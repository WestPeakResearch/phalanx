class AddSelectedForInterviewToApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :applications, :selected_for_interview, :boolean, default: false, null: false
  end
end
