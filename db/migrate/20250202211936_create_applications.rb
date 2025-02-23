class CreateApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :applications do |t|
      t.datetime :application_date
      t.string :email
      t.string :first_name
      t.string :last_name
      t.integer :student_number
      t.string :faculty
      t.string :major
      t.integer :year
      t.string :grad_year
      t.string :position
      t.string :resume
      t.string :additional
      t.string :source
      t.string :group_preference
      t.string :countries
      t.string :careers

      t.timestamps
    end
  end
end
