# The entrant-photo management workflow races itself: manage_entrant_photos renders variant <img>
# URLs while assign_entrant_photos re-parents attachments and the delete paths purge_later. A variant
# request for a photo whose blob/file is mid-purge or gone makes the stock
# ActiveStorage::Representations::RedirectController raise -> 500 (see #2161). Rescue that class of
# missing-data errors and serve the empty-avatar placeholder instead. Mirrors config/initializers/
# health_check.rb, which patches a framework controller the same way.
Rails.application.config.to_prepare do
  # The Aws::S3::Errors classes are passed as strings so rescue_from resolves them lazily at raise
  # time: aws-sdk-s3 is require: false and only loaded when the S3 service is in use, so referencing
  # the constants here (at boot) would fail. When an S3 error actually fires, the SDK is loaded.
  ActiveStorage::Representations::RedirectController.rescue_from(
    ActiveStorage::FileNotFoundError,
    ActiveRecord::InvalidForeignKey,
    "Aws::S3::Errors::NoSuchKey",
    "Aws::S3::Errors::NotFound",
  ) do
    redirect_to helpers.image_path("avatar-placeholder.svg"), allow_other_host: false
  end
end
