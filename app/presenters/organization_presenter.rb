class OrganizationPresenter < BasePresenter

  attr_reader :organization
  delegate :id, :name, :description, :stewards, :to_param, to: :organization

  def initialize(organization, params, current_user)
    @organization = organization
    @params = params
    @current_user = current_user
  end

  def events
    @events ||= EventPolicy::Scope.new(current_user, Event).viewable
                    .includes(:event_group).where(event_groups: {organization: organization})
                    .select_with_params(search_text).order(start_time: :desc).to_a
  end

  def courses
    @courses ||= Course.used_for_organization(organization)
  end

  def events_count
    events.size
  end

  def courses_count
    courses.size
  end

  def stewards_count
    stewards.size
  end

  def view_text
    case params[:view]
    when 'courses'
      'courses'
    when 'stewards'
      'stewards'
    else
      'events'
    end
  end

  def show_visibility_columns?
    current_user.authorized_to_edit?(organization)
  end

  private

  attr_reader :params, :current_user
end
