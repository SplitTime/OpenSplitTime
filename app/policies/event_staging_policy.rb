class EventStagingPolicy < Struct.new(:current_user, :controller)

  def get_countries?
    current_user.present?
  end
end