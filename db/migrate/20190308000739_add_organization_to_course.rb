class AddOrganizationToCourse < ActiveRecord::Migration[5.2]
  def change
    add_reference :courses, :organization, foreign_key: true

    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
        UPDATE courses
           SET organization_id = (SELECT distinct on (courses.id) event_groups.organization_id
                                  from event_groups 
                                     inner join events on events.event_group_id = event_groups.id
                                  where events.course_id = courses.id)
        SQL
      end
    end
  end
end
