# frozen_string_literal: true

namespace :images do
  desc "Compress effort photos to reduce S3 storage costs"
  task compress: :environment do
    batch_size = ENV.fetch("BATCH_SIZE", 10).to_i
    min_size_kb = ENV.fetch("MIN_SIZE_KB", Images::MIN_SIZE_KB).to_i

    puts "Compressing effort photos (batch: #{batch_size}, min: #{min_size_kb}KB)"
    Images::CompressEffortPhotosJob.perform_now(batch_size: batch_size, min_size_kb: min_size_kb)
    puts "Batch complete"
  end
end
