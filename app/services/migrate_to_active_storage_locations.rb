# frozen_string_literal: true

# Run this migration from the active-storage-changes code branch.

class MigrateToActiveStorageLocations
  def perform
    model_map = {Course => :gpx, Effort => :photo, Partner => :banner, Person => :photo}

    model_map.each do |model, attribute|
      migrate_data(attribute, model)
    end
  end

  private

  def migrate_data(attribute, model)
    model.where.not("#{attribute}_file_name": nil).find_each do |resource|
      name = resource.send("#{attribute}_file_name")
      content_type = resource.send("#{attribute}_content_type")

      url = resource.send(attribute).service_url

      resource.send(attribute.to_sym).attach(io: open(url),
                                             filename: name,
                                             content_type: content_type)
    end
  end
end
