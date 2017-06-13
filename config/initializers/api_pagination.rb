ApiPagination.configure do |config|
  DEFAULT_PER_PAGE ||= 10
  MAX_PER_PAGE ||= 50

  config.page_param do |params|
    if params[:page].is_a? ActionController::Parameters
      params[:page][:number]
    else
      params[:page]
    end
  end

  config.per_page_param do |params|
    if params[:page].is_a? ActionController::Parameters
      size_param = params[:page][:size].present? ? params[:page][:size].to_i : nil
      [size_param || DEFAULT_PER_PAGE, MAX_PER_PAGE].min
    else
      size_param = params[:per_page].present? ? params[:per_page].to_i : nil
      [size_param || DEFAULT_PER_PAGE, MAX_PER_PAGE].min
    end
  end
end
