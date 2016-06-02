class LiveEntryPolicy < Struct.new(:user, :admin)

  def show?
    user.admin?
  end

  def get_event_data?
    user.admin?
  end

  def get_effort?
    user.admin?
  end

  def get_time_from_last?
    user.admin?
  end

  def get_time_spent?
    user.admin?
  end

  def set_split_times?
    user.admin?
  end
  
end
