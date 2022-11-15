class RemoveSearchIndexesFromPeople < ActiveRecord::Migration[5.2]
  def change
    remove_index :people, name: :index_people_on_first_name, using: :gin
    remove_index :people, name: :index_people_on_last_name, using: :gin
    remove_index :people, name: :index_people_on_city, using: :gin
    remove_index :people, name: :index_people_on_state_name, using: :gin
    remove_index :people, name: :index_people_on_country_name, using: :gin

    disable_extension "btree_gin"
  end
end
