namespace :secretary do
  desc "Morning secretary briefing"
  task morning: :environment do
    puts "Running morning secretary..."
    SecretaryRunner.run("/朝")
    puts "Done."
  end

  desc "Night secretary review"
  task night: :environment do
    puts "Running night secretary..."
    SecretaryRunner.run("/夜")
    puts "Done."
  end
end
