# A blob can be purged before its ActiveStorage::AnalyzeJob runs (e.g. the entrant-photo management
# workflow re-parents/deletes attachments right after upload), so the analyze download hits a file that's
# gone -> Aws::S3 NotFound/NoSuchKey or FileNotFoundError, retried and reported (see #2161, Scout #117837).
# Discard those: there's nothing to analyze once the file is gone. Aws errors are strings so rescue_from
# resolves them lazily at raise time (aws-sdk-s3 is require: false, not loaded at boot).
Rails.application.config.to_prepare do
  ActiveStorage::AnalyzeJob.discard_on(
    ActiveStorage::FileNotFoundError,
    "Aws::S3::Errors::NoSuchKey",
    "Aws::S3::Errors::NotFound",
  )
end
