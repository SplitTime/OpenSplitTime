class AddBirthdateToEfforts < ActiveRecord::Migration
  def change
    add_column :efforts, :birthdate, :date
  end
end
