class AddUserForeignKeysToRawTimes < ActiveRecord::Migration[7.2]
  def change
    # Rename columns to follow Rails conventions
    rename_column :raw_times, :created_by, :creator_id
    rename_column :raw_times, :reviewed_by, :reviewer_id

    # Add indexes for foreign keys
    add_index :raw_times, :creator_id
    add_index :raw_times, :reviewer_id

    # Add foreign key constraints with nullify on delete
    add_foreign_key :raw_times, :users, column: :creator_id, on_delete: :nullify
    add_foreign_key :raw_times, :users, column: :reviewer_id, on_delete: :nullify
  end
end
