class AddPhotoUrlToParticipants < ActiveRecord::Migration
  def change
    add_column :participants, :photo_url, :string
  end
end
