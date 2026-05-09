class BackfillFieldMappingsToRaceConnection < ActiveRecord::Migration[8.1]
  # Per #1998 follow-up: field_mappings is now stored on the EventGroup-level
  # Race Connection rather than the per-event Connections. Production has the
  # canonical mapping on per-event Connections (set via console snippets while
  # iterating on the design). Copy each EventGroup's first non-empty per-event
  # field_mappings onto its Race Connection so the new UI / sync read path
  # finds the data where it now expects it.
  def up
    Connection.where(service_identifier: "runsignup", source_type: "Race").find_each do |race_conn|
      next if race_conn.field_mappings.present?

      event_group = race_conn.destination
      next unless event_group.is_a?(EventGroup)

      first_non_empty = event_group.events.flat_map do |event|
        event.connections.where(service_identifier: "runsignup", source_type: "Event").to_a
      end.map(&:field_mappings).find(&:present?)

      next if first_non_empty.blank?

      race_conn.update_column(:field_mappings, first_non_empty)
      say "Backfilled field_mappings onto Race Connection ##{race_conn.id} (EventGroup ##{event_group.id})"
    end
  end

  def down
    # No-op. Reverse direction is ambiguous (which per-event Connection(s) to
    # populate?) and not useful — the new code reads from Race-level only.
  end
end
