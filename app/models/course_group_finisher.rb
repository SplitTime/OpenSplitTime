class CourseGroupFinisher < ::ApplicationRecord
  include PersonalInfo
  include Searchable

  self.primary_key = :id

  belongs_to :person
  belongs_to :course_group

  scope :for_course_groups, ->(course_groups) { where(course_group_id: course_groups) }

  def self.search(param)
    return all unless param && param.size > 2

    search_names_and_locations(param)
  end

  def display_full_name
    person ? person.display_full_name : full_name
  end

  def display_first_name
    person ? person.display_first_name : first_name
  end
end
