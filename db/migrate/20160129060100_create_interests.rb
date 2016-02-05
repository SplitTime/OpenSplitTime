class CreateInterests < ActiveRecord::Migration
  def change
    create_table :interests do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.belongs_to :participant, index: true, foreign_key: true
      t.integer :kind

      t.timestamps null: false
    end

    add_index :interests, ["user_id", "participant_id"], :unique => true
  end
end
