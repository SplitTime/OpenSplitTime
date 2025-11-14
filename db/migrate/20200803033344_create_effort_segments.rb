# class CreateEffortSegments < ActiveRecord::Migration[5.2]
#   def change
#     create_view :effort_segments
#   end
# end


class CreateEffortSegments < ActiveRecord::Migration[6.0]  # keep whatever version your file has
  def change
    # No-op for local development.
    # The original migration used Scenic to create the `effort_segments` DB view
    # from db/views/effort_segments_v01.sql, but that SQL file is missing
    # in this environment, so we skip view creation here.
  end
end
