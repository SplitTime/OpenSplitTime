class BasePresenter
  DEFAULT_PER_PAGE = 50
  FIRST_PAGE = 1

  def initialize(_args)
    raise NotImplementedError, "#{self.class.name} is an abstract class."
  end

  def action_name
    view_context.action_name
  end

  def controller_name
    view_context.controller_name
  end

  def existing_sort
    params.original_params[:sort]
  end

  def filter_hash
    params[:filter] || {}
  end

  def gender_text
    case genders
    when [0]
      "male"
    when [1]
      "female"
    when [2]
      "nonbinary"
    else
      "combined"
    end
  end

  def genders
    filter_hash[:gender] || [0, 1, 2]
  end

  def page
    result = params[:page]&.to_i || FIRST_PAGE
    result == 0 ? FIRST_PAGE : result
  end

  def per_page
    result = params[:per_page]&.to_i || DEFAULT_PER_PAGE
    result == 0 ? DEFAULT_PER_PAGE : result
  end

  def request_params_digest
    ::OpenSSL::Digest::MD5.base64digest(params.to_json)
  end

  def search_text
    params[:search]
  end

  def sort_hash
    params[:sort]
  end

  def sort_string
    sort_hash.map { |field, direction| "#{(direction == :desc ? '-' : '')}#{field}" }.join(",")
  end

  private

  def params
    raise NotImplementedError, "#{self.class.name} must implement a params method."
  end
end
