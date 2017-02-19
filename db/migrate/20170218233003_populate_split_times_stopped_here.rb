class PopulateSplitTimesStoppedHere < ActiveRecord::Migration
  def change
    reversible do |direction|
      direction.up do
        Event.all.each do |event|
          event_finished = event.finished?
          event.efforts.sorted_with_finish_status.each do |effort|
            split_time = effort.split_times.find_by(id: effort.final_split_time_id)
            split_time.update(stopped_here: true) if event_finished || effort.dropped_split_id
          end
        end
      end
    end
  end
end