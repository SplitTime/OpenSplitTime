class EventStagingPolicy < Struct.new(:user, :controller)

  def new?
    user.present?
  end
end