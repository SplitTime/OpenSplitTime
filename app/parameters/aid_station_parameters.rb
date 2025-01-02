class AidStationParameters < BaseParameters
  def self.permitted
    [:event_id, :split_id]
  end
end
