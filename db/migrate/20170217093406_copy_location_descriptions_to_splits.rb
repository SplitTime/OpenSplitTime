class CopyLocationDescriptionsToSplits < ActiveRecord::Migration
  def change
    reversible do |direction|
      direction.up do
        Split.where.not(location_id: nil).each do |split|
          location = split.location
          description = [split.description, location.name, location.description].compact.uniq.join(' / ')
          split.update(description: description)
        end
      end
    end
  end
end