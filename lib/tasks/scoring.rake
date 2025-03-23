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
        interest_score: rand(1..5),
        alignment_score: rand(1..5),
        polish_score: rand(1..5),
        comments: "Auto-generated random scoring",
      )
      print "."
    end

    puts "\nDone! Assigned random scores to #{total} scorings."
  end
end
