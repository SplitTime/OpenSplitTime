class BasePresenter

  def initialize(args)
    raise NotImplementedError, "#{self.class.name} is an abstract class."
  end

  def current_user
    params[:current_user]
  end

  def filter_hash
    params[:filter] || {}
  end

  def genders
    filter_hash[:gender] || [0, 1]
  end

  def page
    params[:page]
  end

  def per_page
    params[:per_page] || 25
  end

  def search_text
    params[:search]
  end

  def sort_hash
    params[:sort]
  end

  def sort_string
    sort_hash.map { |field, direction| "#{(direction == :desc ? '-' : '')}#{field}" }.join(',')
  end

  private

  def params
    raise NotImplementedError, "#{self.class.name} must implement a params method."
  end
end
