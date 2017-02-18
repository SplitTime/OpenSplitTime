class AddLocationFieldsToSplits < ActiveRecord::Migration
  def change
    add_column :splits, :latitude, :decimal, precision: 9, scale: 6
    add_column :splits, :longitude, :decimal, precision: 9, scale: 6
    add_column :splits, :elevation, :float
    reversible do |direction|
      direction.up do
        Split.where.not(location_id: nil).each do |split|
          location_attributes = split.location.attributes.slice('latitude', 'longitude', 'elevation')
          split.update(location_attributes)
        end
      end
    end
  end
end