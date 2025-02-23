class CreateInitialReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :initial_reviews do |t|
      t.references :application, null: false, foreign_key: true
      t.integer :decision
      t.string :reviewer

      t.timestamps
    end
  end
end
