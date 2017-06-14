class OrganizationPresenter < BasePresenter

  attr_reader :organization
  delegate :id, :name, :description, :stewards, :to_param, to: :organization

  def initialize(organization, params)
    @organization = organization
    @params = params
  end

  def events
    @events ||= EventPolicy::Scope.new(current_user, Event).viewable.where(organization: organization)
                    .select_with_params(search_text).to_a
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

  private

  attr_reader :params
end
