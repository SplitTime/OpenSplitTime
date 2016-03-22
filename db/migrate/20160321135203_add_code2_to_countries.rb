class AddCode2ToCountries < ActiveRecord::Migration
  def change
    add_column :countries, :code2, :string, :limit => 2  # ISO 3166 2-character country code
  end
end
