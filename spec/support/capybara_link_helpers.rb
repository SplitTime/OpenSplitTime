module CapybaraLinkHelpers
  def verify_link_present(resource, attr = :name)
    path = polymorphic_url(resource, routing_type: :path)
    expect(page).to have_link(resource.send(attr), href: path)
  end

  def verify_content_present(resource, attr = :name)
    expect(page).to have_content(resource.send(attr))
  end

  def verify_content_absent(resource, attr = :name)
    expect(page).not_to have_content(resource.send(attr))
  end

  def verify_alert(text)
    expect(page.find('.alert')).to have_content(text)
  end
end
