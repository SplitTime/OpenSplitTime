# require "active_record"

desc "merges one organization into another"
task :merge_organizations, [:disappearing_organization_id, :surviving_organization_id] => :environment do |_, args|
  disappearing_organization = Organization.find_by(id: args.disappearing_organization_id)
  surviving_organization = Organization.find_by(id: args.surviving_organization_id)

  abort if disappearing_organization.nil? || surviving_organization.nil?

  puts "This will merge #{disappearing_organization.name} into #{surviving_organization.name}"
  puts "Are you sure you want to do this? (y/n)"
  answer = STDIN.gets.chomp
  abort unless answer.downcase == "y"

  relevant_models = [
    Course,
    CourseGroup,
    EventGroup,
    EventSeries,
    Lottery,
    ResultsCategory,
    ResultsTemplate,
    Stewardship,
  ]

  relevant_models.each do |model|
    puts "Merging #{model.table_name.titleize.pluralize}"
    model.where(organization: disappearing_organization).update_all(organization_id: surviving_organization.id)
  end
end
