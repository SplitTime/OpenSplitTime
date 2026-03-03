# Pagy Configuration
# See https://ddnexus.github.io/pagy/

# Pagy has a major redesign in v43:
# - v9 uses Pagy::DEFAULT and optional extras
# - v43 uses Pagy::OPTIONS and integrates many extras

if defined?(Pagy::OPTIONS)
  # Pagy v43+
  Pagy::OPTIONS[:items] = 25
  # Out-of-range handling: v43 serves an empty page by default.
  # If you prefer raising exceptions, set: Pagy::OPTIONS[:raise_range_error] = true
else
  # Pagy v9.x
  require "pagy/extras/overflow"

  Pagy::DEFAULT[:items] = 25
  # Preserve historical behavior until we upgrade:
  Pagy::DEFAULT[:overflow] = :last_page
end
