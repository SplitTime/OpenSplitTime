CSV.generate do |csv|
  csv << @builder.headers
  @builder.resources.each do |resource|
    csv << @builder.export_attributes.map { |attribute| resource.send(attribute) }
  end
end
