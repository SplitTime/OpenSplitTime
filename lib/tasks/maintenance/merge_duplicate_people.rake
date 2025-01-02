namespace :maintenance do
  desc "Merges all duplicate people in the database"
  task merge_duplicate_people: :environment do
    puts "Attempting to merge all duplicate people in the database"

    email_counts = ::Person.select("first_name, last_name, email, count(email) as duplicates").group("first_name, last_name, email")
    duplicate_structs = ::Person.where("duplicates > ?", 1).from(email_counts, "people").struct_pluck(:email, :first_name, :last_name)
    duplicate_count = duplicate_structs.size

    puts "Found #{duplicate_count} duplicated people"

    progress_bar = ::ProgressBar.new(duplicate_count)

    duplicate_structs.each do |struct|
      progress_bar.increment!
      people_to_merge = ::Person.where(email: struct.email, first_name: struct.first_name, last_name: struct.last_name).order(:id).to_a
      master_record = people_to_merge.shift

      people_to_merge.each { |target| ::Interactors::MergePeople.perform!(master_record, target) }
    rescue ActiveRecordError => e
      puts "Could not merge person with email #{email}:"
      puts e
    end
  end
end
