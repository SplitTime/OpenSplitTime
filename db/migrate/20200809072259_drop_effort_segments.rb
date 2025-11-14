# class DropEffortSegments < ActiveRecord::Migration[5.2]
#   def change
#     drop_view :effort_segments
#   end
# end

class DropEffortSegments < ActiveRecord::Migration[6.0]  # keep your version number
  def change
    # No-op for local development.
    # The `effort_segments` view was never created in this environment,
    # so there is nothing to drop here.
  end
end
