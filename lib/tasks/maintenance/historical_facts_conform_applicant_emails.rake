# frozen_string_literal: true

namespace :maintenance do
  desc "Changes people emails to match historical facts emails for lottery applicants"
  task historical_facts_conform_applicant_emails: :environment do
    puts "Conforming people emails to match historical facts emails for lottery applicants"

    people = Person.joins(:historical_facts)
      .where(historical_facts: { kind: :lottery_application} )
      .where("historical_facts.email is not null and historical_facts.email <> people.email")
      .distinct
    person_count = people.count

    puts "Found #{person_count} people to update"

    progress_bar = ::ProgressBar.new(person_count)

    people.find_each do |person|
      progress_bar.increment!

      if person.user_id?
        puts "Person #{person.id} has an associated user; skipping"
        next
      end

      fact = person.historical_facts.find_by(kind: :lottery_application)
      person.update(email: fact.email)
    rescue ActiveRecordError => e
      puts "Could not update record for Person id: #{person.id}"
      puts e
    end
  end
end
