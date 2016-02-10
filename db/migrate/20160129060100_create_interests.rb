class CreateInterests < ActiveRecord::Migration
  def change
    create_table :interests do |t|
      t.belongs_to :user, index: true, foreign_key: true, :null => false
      t.belongs_to :participant, index: true, foreign_key: true, :null => false
      t.integer :kind, default: 0, :null => false

      t.timestamps null: false
    end

    add_index :interests, ["user_id", "participant_id"], :unique => true
  end
end
