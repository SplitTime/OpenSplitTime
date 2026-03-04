# Pagy Configuration
# See https://ddnexus.github.io/pagy/

require "pagy/extras/overflow"

Pagy::DEFAULT[:limit] = 25
Pagy::DEFAULT[:overflow] = :last_page
