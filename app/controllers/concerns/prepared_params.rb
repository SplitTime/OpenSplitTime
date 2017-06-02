class PreparedParams

  def initialize(params, permitted, permitted_query = nil)
    @params = params
    @permitted = permitted.map(&:to_s)
    @permitted_query = (permitted_query || permitted).map(&:to_s)
  end

  def [](method_name)
    send(method_name)
  end

  def data
    @data ||= ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: permitted).with_indifferent_access
  end

  def sort
    @sort ||= sort_hash.reject {|field, _| permitted_query.exclude?(field)}.with_indifferent_access
  end

  def fields
    @fields ||= (params[:fields] || {})
                    .map {|resource, fields| {resource => fields.split(',').map {|field| field.underscore.to_sym}}}
                    .reduce({}, :merge).with_indifferent_access
  end

  def include
    @include ||= params[:include].to_s.underscore
  end

  def filter
    return @filter if defined?(@filter)
    filter_params = transformed_filter_values
    filter_params['gender'] = prepare_gender(filter_params['gender']) if filter_params.has_key?('gender')
    @filter = filter_params.with_indifferent_access
  end

  def search
    @search ||= (params[:filter] || {})[:search].to_s.presence
  end

  def page
    params[:page].is_a?(Hash) ? params[:page][:number] : params[:page]
  end

  def per_page
    params[:page].is_a?(Hash) ? params[:page][:size] : params[:per_page]
  end

  def method_missing(method)
    params[method]
  end

  private

  attr_reader :params, :permitted, :permitted_query

  def transformed_filter_values
    permitted_filter_params.transform_values do |list|
      items = list.is_a?(Array) ? list : list.to_s.split(',')
      items.size > 1 ? items : items.first.presence
    end
  end

  def prepare_gender(gender_params)
    gender_enums = Array.wrap(gender_params).map { |param| param.numeric? ? param.to_i : Effort.genders[param] }
    gender_enums.compact.presence || Effort.genders.values
  end

  def sort_hash
    sort_fields.each_with_object({}) do |field, hash|
      if field.start_with?('-')
        hash[field[1..-1].underscore] = :desc
      else
        hash[field.underscore] = :asc
      end
    end
  end

  def permitted_filter_params
    params[:filter]&.to_unsafe_hash.to_h.slice(*permitted_query) || {}
  end

  def sort_fields
    params[:sort].to_s.split(',')
  end
end