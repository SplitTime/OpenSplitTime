# frozen_string_literal: true

require_relative "errors"
require_relative "extractor"
require_relative "transformer"
require_relative "loader"
require_relative "transformable"

# Importers

require_relative "event_group_import_process"
require_relative "event_import_process"
require_relative "importer"
require_relative "importer_from_context"

# Extractors
Dir.glob("lib/etl/extractors/**/*.rb") { |file| require Rails.root.join(file) }

# Transformers
require_relative "transformers/base_transformer"
Dir.glob("lib/etl/transformers/**/*.rb") { |file| require Rails.root.join(file) }

# Loaders

require_relative "loaders/base_loader"
Dir.glob("lib/etl/loaders/**/*.rb") { |file| require Rails.root.join(file) }

# Helpers
Dir.glob("lib/etl/helpers/**/*.rb") { |file| require Rails.root.join(file) }
