namespace :initial_review do
  desc "Assign random decisions to all pending initial reviews"
  task randomize_pending: :environment do
    pending_reviews = InitialReview.where(decision: :pending)
    total = pending_reviews.count

    if total == 0
      puts "No pending initial reviews found."
      exit
    end

    puts "Found #{total} pending initial reviews. Assigning random decisions..."

    decisions = [:no, :maybe, :yes]
    pending_reviews.each do |review|
      review.update!(
        decision: decisions.sample,
      )
      print "."
    end

    puts "\nDone! Assigned random decisions to #{total} initial reviews."
  end
end
