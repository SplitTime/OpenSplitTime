# Pagy Configuration
# See https://ddnexus.github.io/pagy/docs/api/pagy/

require "pagy/extras/overflow"

# Default items per page
Pagy::DEFAULT[:items] = 25

# Handle out-of-range pages gracefully
Pagy::DEFAULT[:overflow] = :last_page
