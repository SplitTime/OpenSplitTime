class AddAttachmentPhotoToEfforts < ActiveRecord::Migration
  def self.up
    change_table :efforts do |t|
      t.attachment :photo
    end
  end

  def self.down
    remove_attachment :efforts, :photo
  end
end
