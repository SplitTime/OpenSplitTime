module FileUploadHelpers
  def upload_to_dropzone(fixture_name)
    path = file_fixture(fixture_name).to_s

    # 1) Find the hidden input Dropzone wires up (it’s often appended near <body>)
    input = page.find("input[type='file'].dz-hidden-input", visible: :all, wait: 5)
    input.set(path)
    input.trigger("change") # harmless if redundant

    # 2) Wait for Dropzone to register the file (prevents races with the click)
    # Prefer success, but preview is okay if you don’t use autoProcessQueue
    expect(page).to have_css(".dz-file-preview", wait: 5)
    # If your Dropzone auto-processes on add, use:
    # expect(page).to have_css(".dz-success", wait: 5)
  end
end

RSpec.configure do |config|
  config.include FileUploadHelpers, type: :system
end
