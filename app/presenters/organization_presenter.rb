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
    @courses ||= Course.includes(:splits, :events).used_for_organization(organization)
  end

  def display_style
    %w[courses stewards events].include?(params[:display_style]) ? params[:display_style] : default_display_style
  end

  def default_display_style
    'events'
  end

  def show_visibility_columns?
    current_user&.authorized_to_edit?(organization)
  end

  private

  attr_reader :params, :current_user
end
