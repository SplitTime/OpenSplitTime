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

  # Cuprite-compatible file upload for Dropzone
  def upload_to_dropzone(fixture_name)
    path = file_fixture(fixture_name).to_s

    # Find the hidden input Dropzone wires up (often appended near <body>)
    input = page.find("input[type='file'].dz-hidden-input", visible: :all, wait: 5)
    input.set(path)
    input.trigger("change")

    # Wait for Dropzone to register the file (prevents races)
    expect(page).to have_css(".dz-file-preview", wait: 5)
  end

  # Clear masked input fields properly for Cuprite
  def clear_masked_input_and_type(input, value)
    page.execute_script("arguments[0].value = '';", input)
    input.click
    input.native.send_keys(value)
    input.native.send_keys(:tab)
    sleep(0.1) # Allow mask to process
  end

  # Wait for file download to complete
  def wait_for_download(file_path, timeout: 5)
    Timeout.timeout(timeout) do
      sleep 0.1 until File.exist?(file_path)
    end
  rescue Timeout::Error
    # File didn't download in time
  end
end
