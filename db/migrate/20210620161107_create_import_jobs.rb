class CreateImportJobs < ActiveRecord::Migration[6.1]
  def change
    create_table :import_jobs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :parent, null: false, polymorphic: true
      t.string :format, null: false
      t.integer :status
      t.string :error_message
      t.integer :row_count
      t.integer :elapsed_time

      t.timestamps
    end
  end
end
