class AddNullFalseToCoursesOrganizationId < ActiveRecord::Migration[6.1]
  def change
    change_column_null :courses, :organization_id, false
  end
end
