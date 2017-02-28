class AddPhoneAndEmailToEfforts < ActiveRecord::Migration
  def change
    add_column :efforts, :phone, :string, limit: 15
    add_column :efforts, :email, :string
  end
end