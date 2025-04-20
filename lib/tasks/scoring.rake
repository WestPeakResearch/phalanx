namespace :scoring do
  desc "Assign random scores to all pending scorings"
  task randomize_pending: :environment do
    pending_scorings = Scoring.where(status: :pending)
    total = pending_scorings.count

    if total == 0
      puts "No pending scorings found."
      exit
    end

    puts "Found #{total} pending scorings. Assigning random scores..."

    pending_scorings.each do |scoring|
      scoring.update!(
        status: :completed,
        interest_score: (rand * 4 + 1).round(2),
        alignment_score: (rand * 4 + 1).round(2),
        polish_score: (rand * 4 + 1).round(2),
        comments: "Auto-generated random scoring",
      )
      print "."
    end

    puts "\nDone! Assigned random scores to #{total} scorings."
  end
end
