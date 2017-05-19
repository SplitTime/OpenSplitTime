CSV.generate do |csv|
    csv << @presenter.headers
    @presenter.resources.each { |resource| csv << resource.attributes.map { |attribute| resource.send(attribute) } }
end
