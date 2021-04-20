# frozen_string_literal: true

require_relative "errors"
require_relative "extractor"
require_relative "transformer"
require_relative "loader"

# Importers

require_relative "event_group_import_process"
require_relative "event_import_process"
require_relative "importer"
require_relative "importer_from_context"

# Extractors

require_relative "extractors/adilas_bear_html_strategy"
require_relative "extractors/csv_file_strategy"
require_relative "extractors/its_your_race_html_strategy"
require_relative "extractors/pass_through_strategy"
require_relative "extractors/race_result_api_strategy"
require_relative "extractors/race_result_strategy"

# Transformers

require_relative "transformers/base_transformer"
require_relative "transformers/adilas_bear_strategy"
require_relative "transformers/efforts_with_times_strategy"
require_relative "transformers/elapsed_incremental_aid_strategy"
require_relative "transformers/generic_resources_strategy"
require_relative "transformers/jsonapi_batch_strategy"
require_relative "transformers/race_result_api_split_times_strategy"
require_relative "transformers/race_result_entrants_strategy"
require_relative "transformers/race_result_split_times_strategy"

# Loaders

require_relative "loaders/base_loader"
require_relative "loaders/insert_strategy"
require_relative "loaders/split_time_upsert_strategy"
require_relative "loaders/upsert_strategy"
