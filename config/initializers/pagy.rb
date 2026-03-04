# Pagy Configuration
# See https://ddnexus.github.io/pagy/

# Pagy v43+ Configuration
Pagy::OPTIONS[:limit] = 25
Pagy::OPTIONS[:max_per_page] = 100

# Overflow behavior is now built-in by default (serves empty page for out-of-range)
# The old :last_page behavior is discontinued in v43+
# Default behavior: serve empty page for out-of-range requests (equivalent to old :empty_page)
