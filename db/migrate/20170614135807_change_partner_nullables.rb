class ChangePartnerNullables < ActiveRecord::Migration
  def change
    change_column_null :partners, :name, false
    change_column_null :partners, :banner_link, true
  end
end
