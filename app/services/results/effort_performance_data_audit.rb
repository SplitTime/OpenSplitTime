module Results
  # Detects efforts whose stored overall_performance no longer matches the
  # split time it was derived from. The bit positions here mirror the packing
  # in Results::SetEffortPerformanceData: finished flag (1 bit), lap (14),
  # distance_from_start (30), sub_split_bitkey (7), inverted elapsed ms (44).
  # Staleness arises when a split's distance_from_start (or sub split bitmap)
  # changes after an event's results were derived; ranks stay consistent until
  # a single effort is recomputed on the new basis, which vaults it over its
  # stale neighbors because distance outranks elapsed time in the packing.
  class EffortPerformanceDataAudit
    STALE_PREDICATE = <<~SQL.squish.freeze
      efforts.overall_performance is not null
        and efforts.overall_performance <> 0::bit(96)
        and (substring(efforts.overall_performance from 2 for 14) <> split_times.lap::bit(14)
          or substring(efforts.overall_performance from 16 for 30) <> splits.distance_from_start::bit(30)
          or substring(efforts.overall_performance from 46 for 7) <> split_times.sub_split_bitkey::bit(7))
    SQL

    def self.stale_for_event?(event)
      stale_efforts(event.efforts).exists?
    end

    def self.stale_event_ids
      stale_efforts(::Effort.all).distinct.pluck(:event_id)
    end

    def self.stale_efforts(efforts)
      efforts.joins("join split_times on split_times.id = efforts.final_split_time_id")
             .joins("join splits on splits.id = split_times.split_id")
             .where(STALE_PREDICATE)
    end
    private_class_method :stale_efforts
  end
end
