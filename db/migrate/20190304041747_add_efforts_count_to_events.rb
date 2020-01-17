class AddEffortsCountToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :efforts_count, :integer, default: 0

    reversible do |dir|
      dir.up { data }
    end
  end

  def data
    execute <<-SQL.squish
        UPDATE events
           SET efforts_count = (SELECT count(1)
                                   FROM efforts
                                  WHERE efforts.event_id = events.id)
    SQL
  end
end
