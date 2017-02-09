class EventStagingPolicy < Struct.new(:current_user, :controller)

  def new?
    current_user.present?
  end
end