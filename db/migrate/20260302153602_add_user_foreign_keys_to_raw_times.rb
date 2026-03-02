class AddUserForeignKeysToRawTimes < ActiveRecord::Migration[7.2]
  def up
    # Clean up invalid created_by references
    execute <<-SQL.squish
      UPDATE raw_times
      SET created_by = NULL
      WHERE created_by IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM users WHERE users.id = raw_times.created_by
        )
    SQL

    # Clean up invalid reviewed_by references
    execute <<-SQL.squish
      UPDATE raw_times
      SET reviewed_by = NULL
      WHERE reviewed_by IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM users WHERE users.id = raw_times.reviewed_by
        )
    SQL

    # Add indexes for foreign keys
    add_index :raw_times, :created_by
    add_index :raw_times, :reviewed_by

    # Add foreign key constraints with nullify on delete
    add_foreign_key :raw_times, :users, column: :created_by, on_delete: :nullify
    add_foreign_key :raw_times, :users, column: :reviewed_by, on_delete: :nullify
  end

  def down
    remove_foreign_key :raw_times, column: :reviewed_by
    remove_foreign_key :raw_times, column: :created_by
    remove_index :raw_times, :reviewed_by
    remove_index :raw_times, :created_by
  end
end
