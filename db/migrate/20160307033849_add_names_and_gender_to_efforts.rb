class AddNamesAndGenderToEfforts < ActiveRecord::Migration
  def change
    add_column :efforts, :first_name, :string
    add_column :efforts, :last_name, :string
    add_column :efforts, :gender, :integer
  end
end
