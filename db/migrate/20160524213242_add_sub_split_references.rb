class AddSubSplitReferences < ActiveRecord::Migration
  def self.up
    add_column :splits, :sub_split_mask, :integer, default: 1 # Defaults to 'in' only
    add_column :splits, :base_split_id, :integer
    add_reference :split_times, :sub_split, index: true
    add_column :split_times, :legacy_split_id, :integer # For safety in migrating to new schema
    add_foreign_key :split_times, :sub_splits, primary_key: :bitkey

    # For 'in' splits that have a corresponding 'out' split, set sub_split_mask to 65 (1000001)

    execute ("UPDATE splits
SET sub_split_mask = 65
FROM
((SELECT DISTINCT ON (to_char(distance_from_start, '9999999999') || '-' || course_id)
SUM(CASE WHEN sub_order = 0 THEN id END) AS in_id,
SUM(CASE WHEN sub_order = 1 THEN id END) AS out_id
FROM splits
GROUP BY (to_char(distance_from_start, '9999999999') || '-' || course_id)
) pt
INNER JOIN splits s ON s.id = pt.out_id) ijt
WHERE
splits.id = ijt.in_id")

    # For 'out' splits, set base_split_id to corresponding 'in' split

    execute ("UPDATE splits
SET base_split_id = ijt.in_id
FROM
((SELECT DISTINCT ON (to_char(distance_from_start, '9999999999') || '-' || course_id)
SUM(CASE WHEN sub_order = 0 THEN id END) AS in_id,
SUM(CASE WHEN sub_order = 1 THEN id END) AS out_id
FROM splits
GROUP BY (to_char(distance_from_start, '9999999999') || '-' || course_id)
) pt
INNER JOIN splits s ON s.id = pt.out_id) ijt
WHERE
splits.id = ijt.out_id")

    # Fill remaining base_split_ids with self.id

    execute ("UPDATE splits SET base_split_id = id WHERE base_split_id IS NULL")

    # Set the new split_time.sub_split_id fields

    execute ("UPDATE split_times SET sub_split_id = 1 FROM splits WHERE splits.id = split_times.split_id AND splits.sub_order = 0")
    execute ("UPDATE split_times SET sub_split_id = 64 FROM splits WHERE splits.id = split_times.split_id AND splits.sub_order = 1")
    execute ("UPDATE split_times SET legacy_split_id = split_id")
    execute ("UPDATE split_times SET split_id = base_split_id FROM splits WHERE splits.id = split_times.split_id")

  end

  def self.down
    execute ("UPDATE split_times SET split_id = legacy_split_id")
    remove_column :splits, :sub_split_mask
    remove_column :splits, :base_split_id
    remove_column :split_times, :sub_split_id
    remove_column :split_times, :legacy_split_id
  end
end
