class EffortChangeDroppedToInteger < ActiveRecord::Migration
  def self.up
    add_column :efforts, :dropped_split_id, :integer
    dropped_splits = SplitTime.joins(:split).joins(:effort)
                         .select('DISTINCT ON (efforts.id) split_times.effort_id, split_times.split_id')
                         .where(efforts: {dropped: true})
                         .order('efforts.id').order('splits.distance_from_start DESC').order('splits.sub_order DESC')
    update_hash = Hash[dropped_splits.map { |x| [x.effort_id, {dropped_split_id: x.split_id, updated_at: Time.now}] }]
    Effort.update(update_hash.keys, update_hash.values)
    remove_column :efforts, :dropped, :boolean
  end

  def self.down
    add_column :efforts, :dropped, :boolean
    Effort.where.not(dropped_split_id: nil).all.update_all(dropped: true)
    Effort.where(dropped_split_id: nil).all.update_all(dropped: false)
    remove_column :efforts, :dropped_split_id, :integer
  end

end
