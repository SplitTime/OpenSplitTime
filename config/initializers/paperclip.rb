Paperclip.options[:content_type_mappings] = {gpx: %w[application/gpx+xml text/xml application/xml application/octet-stream]}
Paperclip::UriAdapter.register
