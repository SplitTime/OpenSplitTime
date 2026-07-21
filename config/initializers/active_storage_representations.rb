# The entrant-photo management workflow races itself: manage_entrant_photos renders variant <img>
# URLs while assign_entrant_photos re-parents attachments and the delete paths purge_later. A variant
# request for a photo whose blob/file is mid-purge or gone makes the stock
# ActiveStorage::Representations::RedirectController raise -> 500 (see #2161). Rescue that class of
# missing-data errors and serve the empty-avatar placeholder, sized to the variant that was requested
# so it fills the same box the real thumbnail would have. Mirrors config/initializers/health_check.rb,
# which patches a framework controller the same way.
Rails.application.config.to_prepare do
  placeholder_svg = Rails.root.join("app/assets/images/avatar-placeholder.svg").read

  # The Aws::S3::Errors classes are passed as strings so rescue_from resolves them lazily at raise
  # time: aws-sdk-s3 is require: false and only loaded when the S3 service is in use, so referencing
  # the constants here (at boot) would fail. When an S3 error actually fires, the SDK is loaded.
  ActiveStorage::Representations::RedirectController.rescue_from(
    ActiveStorage::FileNotFoundError,
    ActiveRecord::InvalidForeignKey,
    "Aws::S3::Errors::NoSuchKey",
    "Aws::S3::Errors::NotFound",
  ) do
    # Pull the requested variant's pixel size out of the variation (e.g. resize_to_limit: [200, 200])
    # so the placeholder matches the box; fall back to the SVG's own 50x50 if it can't be determined.
    width, height = begin
      ActiveStorage::Variation.decode(params[:variation_key]).transformations.values
                              .find { |value| value.is_a?(Array) && value.size == 2 && value.all?(Integer) }
    rescue StandardError
      nil
    end || [50, 50]

    render body: placeholder_svg.sub(/width="\d+" height="\d+"/, %(width="#{width}" height="#{height}")),
           content_type: "image/svg+xml"
  end
end
