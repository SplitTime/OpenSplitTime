class RemovePhoneLengthConstraintFromEfforts < ActiveRecord::Migration[7.1]
  def up
    change_column :efforts, :phone, :string, limit: nil
  end

  def down
    change_column :efforts, :phone, :string, limit: 15
  end
end
