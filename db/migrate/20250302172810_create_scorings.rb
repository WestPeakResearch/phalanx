class CreateScorings < ActiveRecord::Migration[8.0]
  def change
    create_table :scorings do |t|
      t.references :application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :resume_score
      t.integer :experience_score
      t.integer :education_score
      t.integer :fit_score
      t.integer :overall_score
      t.integer :status, default: 0, null: false
      t.text :comments

      t.timestamps
    end

    # Add an index to help with finding applications with less than 2 scorings
    add_index :scorings, [:application_id, :user_id], unique: true
  end
end
