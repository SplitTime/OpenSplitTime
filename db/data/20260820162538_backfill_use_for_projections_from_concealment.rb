class BackfillUseForProjectionsFromConcealment < ActiveRecord::Migration[8.1]
  # Per #2229: use_for_projections replaces the concealment predicate in the
  # projection engine's event selection. Seed it from the current behavior
  # (concealed event groups are excluded) so the flag's introduction is
  # invisible at rollout; after this, the two move independently.
  def up
    updated = execute(<<~SQL.squish)
      update events
      set use_for_projections = false
      from event_groups
      where event_groups.id = events.event_group_id
        and event_groups.concealed is true
    SQL
    say "Set use_for_projections = false on #{updated.cmd_tuples} events in concealed event groups"
  end

  def down
    # No-op. The flag decouples from concealment going forward, so there is
    # no prior state to restore beyond the column default.
  end
end
