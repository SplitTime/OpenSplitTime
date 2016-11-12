module EffortPlaceMethods
  extend ActiveSupport::Concern

  def overall_place
    combined_places[0]
  end

  def gender_place
    combined_places[1]
  end

  private

  def combined_places
    @combined_places ||= effort.combined_places
  end
end
