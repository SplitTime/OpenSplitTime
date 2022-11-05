# frozen_string_literal: true

namespace :maintenance do
  desc "Adds birthdate information to efforts based on person and other effort data"
  task add_missing_birthdates: :environment do
    puts "Attempting to add missing age information"

    ageless_efforts = ::Effort.where(age: nil)
    ageless_count = ageless_efforts.count

    puts "Found #{ageless_count} efforts without ages"

    problem_efforts = []

    progress_bar = ::ProgressBar.new(ageless_count)

    ageless_efforts.find_each do |effort|
      progress_bar.increment!
      person_birthdate = effort.person&.birthdate

      if person_birthdate.present?
        effort.update(birthdate: person_birthdate)
      else
        other_effort_birthdates = effort.person.efforts.where.not(id: effort.id).pluck(:birthdate).uniq
        if other_effort_birthdates.many?
          problem_efforts << "Found conflicting birthdates for effort #{effort.slug}: #{other_effort_birthdates.join(', ')}"
        elsif other_effort_birthdates.one?
          effort.update(birthdate: other_effort_birthdates.first)
        else
          problem_efforts << "No birthdate found for effort #{effort.slug}"
        end
      end
    rescue ActiveRecord::ActiveRecordError => e
      problem_efforts << "Could not update effort #{effort.slug}: #{e}"
    end

    if problem_efforts.present?
      problem_efforts.each { |text| puts text }
    else
      puts "Added birthdate information to all efforts."
    end
  end
end
