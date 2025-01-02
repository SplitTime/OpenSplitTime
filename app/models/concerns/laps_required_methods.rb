module LapsRequiredMethods
  extend ActiveSupport::Concern

  def laps_unlimited?
    laps_required.zero?
  end

  def multiple_laps?
    laps_required != 1
  end

  def single_lap?
    !multiple_laps?
  end

  def maximum_laps
    laps_required unless laps_unlimited?
  end
end
