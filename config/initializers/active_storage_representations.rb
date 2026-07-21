# Missing entrant-photo variants (blob/file purged mid-render) make the stock representation controller
# 500 instead of degrading; rescue those and serve the placeholder, sized to the requested variant (#2161).
Rails.application.config.to_prepare do
  placeholder_svg = Rails.root.join("app/assets/images/avatar-placeholder.svg").read

  # Aws errors as strings: aws-sdk-s3 is require: false, so rescue_from resolves them lazily at raise time.
  ActiveStorage::Representations::RedirectController.rescue_from(
    ActiveStorage::FileNotFoundError,
    ActiveRecord::InvalidForeignKey,
    "Aws::S3::Errors::NoSuchKey",
    "Aws::S3::Errors::NotFound",
  ) do
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
