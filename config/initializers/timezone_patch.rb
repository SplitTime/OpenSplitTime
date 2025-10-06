# Rails maps timezone names to TZInfo names in ActiveSupport::TimeZone::MAPPING
# This constant maps "Greenland" to "America/Godthab", even though that timezone
# was renamed to "America/Nuuk" in 2020. The same is true of "Rangoon", which maps
# to "Asia/Rangoon", even though this is now "Asia/Yangon".

# Postgres recognizes TZInfo names, and newer versions of Postgres no longer
# recognize the deprecated names as valid timezones. As a result, we receive a
# PG error if we attempt to set timezone to a deprecated timezone, e.g.

# set timezone='America/Godthab';
# => PG::InvalidParameterValue

# This file maps certain time zone names to the newer TZInfo names,
# which avoids these PG errors.

ActiveSupport::TimeZone::MAPPING["Greenland"] = "America/Nuuk" # was "America/Godthab"
ActiveSupport::TimeZone::MAPPING["Kyiv"]  = "Europe/Kyiv"   # was "Asia/Rangoon"
ActiveSupport::TimeZone::MAPPING["Rangoon"]  = "Asia/Yangon"   # was "Asia/Rangoon"
