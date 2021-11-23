module CapybaraLinkHelpers
  def verify_link_present(resource_or_array, attr = :name)
    path = polymorphic_url(resource_or_array, routing_type: :path)
    resource = resource_or_array.is_a?(Array) ? resource_or_array.last : resource_or_array
    expect(page).to have_link(resource.send(attr), href: path)
  end

  def verify_content_present(resource, attr = :name)
    expect(page).to have_content(resource.send(attr))
  end

  def verify_content_absent(resource, attr = :name)
    expect(page).not_to have_content(resource.send(attr))
  end

  def verify_alert(text)
    expect(page.find(".alert")).to have_content(text)
  end
end
