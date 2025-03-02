class ChangeReviewerToReferenceInInitialReviews < ActiveRecord::Migration[8.0]
  def up
    # First add the new user_id column
    add_reference :initial_reviews, :user, foreign_key: true

    # Update existing records to use a default user if needed
    # This assumes there's at least one user in the system
    # You may need to adjust this based on your actual data
    if User.exists?
      default_user_id = User.first.id
      InitialReview.where.not(reviewer: nil).update_all(user_id: default_user_id)
    end

    # Remove the old reviewer column
    remove_column :initial_reviews, :reviewer
  end

  def down
    # Add back the reviewer column
    add_column :initial_reviews, :reviewer, :string

    # Migrate data back if needed
    InitialReview.where.not(user_id: nil).each do |review|
      review.update_column(:reviewer, review.user.email) if review.user
    end

    # Remove the user_id column
    remove_reference :initial_reviews, :user
  end
end
