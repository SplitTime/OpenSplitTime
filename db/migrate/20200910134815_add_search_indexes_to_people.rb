class AddSearchIndexesToPeople < ActiveRecord::Migration[5.2]
  def change
    enable_extension "btree_gin"

    add_index :people, :first_name, using: :gin
    add_index :people, :last_name, using: :gin
    add_index :people, :city, using: :gin
    add_index :people, :state_name, using: :gin
    add_index :people, :country_name, using: :gin
  end
end
