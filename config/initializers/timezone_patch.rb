# Rails maps timezone names to TZInfo names in ActiveSupport::TimeZone::MAPPING
# This constant maps "Greenland" to "America/Godthab", even though that timezone
# was renamed to "America/Nuuk" in 2020.

# Postgres recognizes TZInfo names, and newer versions of Postgres no longer
# recognize "America/Godthab" as a valid timezone. As a result, we receive a
# PG error if we attempt to set this timezone:

# set timezone='America/Godthab';

# This file maps "Greenland" to the newer "America/Nuuk" TZInfo name,
# which avoids these PG errors.

ActiveSupport::TimeZone::MAPPING["Greenland"] = "America/Nuuk"