class AddPhotoUrlToEfforts < ActiveRecord::Migration
  def change
    add_column :efforts, :photo_url, :string
  end
end
