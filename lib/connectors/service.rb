module Connectors
  Service = Struct.new(:identifier, :name, :credential_keys, :resource_map, keyword_init: true) do
    def self.all
      [
        new(
          identifier: "internal_lottery",
          name: "OpenSplitTime Lottery",
          credential_keys: %w[],
          resource_map: {
            Event => "Lottery",
          }
        ),
        new(
          identifier: "rattlesnake_ramble",
          name: "Rattlesnake Ramble",
          credential_keys: %w[email password],
          resource_map: {
            Event => "RaceEdition",
          }
        ),
        new(
          identifier: "runsignup",
          name: "RunSignup",
          credential_keys: %w[api_key api_secret],
          resource_map: {
            EventGroup => "Race",
            Event => "Event",
          }
        ),
      ]
    end

    self::BY_IDENTIFIER = all.index_by(&:identifier).with_indifferent_access
    self::IDENTIFIERS = self::BY_IDENTIFIER.keys

    self::SYNCING_INTERACTORS = {
      "internal_lottery" => Interactors::SyncLotteryEntrants,
      "rattlesnake_ramble" => Interactors::SyncRattlesnakeRambleEntries,
      "runsignup" => Interactors::SyncRunsignupParticipants,
    }

    def to_param
      identifier
    end
  end
end
