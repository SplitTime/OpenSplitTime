class AddUserForeignKeysToRawTimes < ActiveRecord::Migration[7.2]
  def change
    # Add indexes for foreign keys
    add_index :raw_times, :created_by
    add_index :raw_times, :reviewed_by

    # Add foreign key constraints with nullify on delete
    add_foreign_key :raw_times, :users, column: :created_by, on_delete: :nullify
    add_foreign_key :raw_times, :users, column: :reviewed_by, on_delete: :nullify
  end
end
