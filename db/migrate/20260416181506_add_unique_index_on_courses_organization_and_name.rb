class AddUniqueIndexOnCoursesOrganizationAndName < ActiveRecord::Migration[8.1]
  def change
    add_index :courses, "organization_id, lower(name)",
              unique: true,
              name: "index_courses_on_organization_id_and_lower_name"
  end
end
