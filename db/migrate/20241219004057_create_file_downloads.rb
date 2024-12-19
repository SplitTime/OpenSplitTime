class CreateFileDownloads < ActiveRecord::Migration[7.0]
  def change
    create_table :file_downloads do |t|
      t.references :user, null: false, foreign_key: true
      t.references :record, polymorphic: true, null: false
      t.string :name, null: false
      t.string :filename, null: false
      t.string :byte_size, null: false

      t.timestamps
    end
  end
end
