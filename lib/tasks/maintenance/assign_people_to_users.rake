namespace :maintenance do
  desc "Assigns people to users where name and email exactly match"
  task assign_people_to_users: :environment do
    puts "Attempting to assign people to users where name and email exactly match"

    people_with_matching_users = ::Person.select("people.*, users.id matching_user_id").joins("inner join users using(first_name, last_name, email)").where(user_id: nil)
    people_count = Person.from(people_with_matching_users, "people").count

    puts "Found #{people_count} people that should be assigned to users"

    progress_bar = ::ProgressBar.new(people_count)

    people_with_matching_users.find_each do |person|
      progress_bar.increment!
      person.update(user_id: person.matching_user_id)
    rescue ActiveRecordError => e
      puts "Could not assign person with email #{person.email}:"
      puts e
    end
  end
end
