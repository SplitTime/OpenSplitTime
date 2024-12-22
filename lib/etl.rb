# frozen_string_literal: true

module Etl
end

require_relative "etl/csv_templates"
require_relative "etl/errors"
require_relative "etl/extractor"
require_relative "etl/transformer"
require_relative "etl/loader"
require_relative "etl/transformable"

# Importers

require_relative "etl/event_group_import_process"
require_relative "etl/event_import_process"
require_relative "etl/importer"
require_relative "etl/importer_from_context"
require_relative "etl/async_importer"

# Extractors
Dir.glob("lib/etl/extractors/**/*.rb") { |file| require Rails.root.join(file) }

# Transformers
require_relative "etl/transformers/base_transformer"
Dir.glob("lib/etl/transformers/**/*.rb") { |file| require Rails.root.join(file) }

# Loaders

require_relative "etl/loaders/base_loader"
Dir.glob("lib/etl/loaders/**/*.rb") { |file| require Rails.root.join(file) }

# Helpers
Dir.glob("lib/etl/helpers/**/*.rb") { |file| require Rails.root.join(file) }
