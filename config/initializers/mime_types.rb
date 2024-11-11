# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

Mime::Type.register "application/vnd.api+json", :jsonapi

# Extend Marcel::MimeType for active_storage_validations

Marcel::MimeType.extend "application/xml", extensions: %w(gpx)
Marcel::MimeType.extend "application/gpx+xml", extensions: %w(gpx), parents: "application/xml"
Marcel::MimeType.extend "application/octet-stream", extensions: %w(gpx), parents: "application/xml"
Marcel::MimeType.extend "text/xml", extensions: %w(gpx), parents: "application/xml"
