class EventGroupParameters < BaseParameters

  def self.permitted
    [:id, :name, :organization_id, :concealed, :available_live, :auto_live_times]
  end
end
