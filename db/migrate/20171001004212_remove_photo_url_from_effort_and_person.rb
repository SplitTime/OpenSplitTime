class RemovePhotoUrlFromEffortAndPerson < ActiveRecord::Migration[5.0]
  def change
    remove_column :efforts, :photo_url, :string
    remove_column :people, :photo_url, :string
  end
end
