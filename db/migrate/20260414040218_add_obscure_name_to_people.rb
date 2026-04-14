class AddObscureNameToPeople < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :obscure_name, :boolean, null: false, default: false
  end
end
