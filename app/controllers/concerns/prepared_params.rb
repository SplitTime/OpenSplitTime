class PreparedParams
  SPECIAL_FILTER_FIELDS = %i(editable search)
  BOOLEAN_FILTER_ATTRIBUTES = %i(ready_to_start)

  def initialize(params, permitted, permitted_query = nil)
    @params = params
    @permitted = permitted.map(&:to_s)
    @permitted_query = (permitted_query || permitted).map(&:to_s)
  end

  def [](method_name)
    send(method_name)
  end

  def data
    @data ||= params.require(:data).require(:attributes).permit(permitted)
  rescue ::ActionController::ParameterMissing
    nil
  end

  def editable
    params[:filter] && params[:filter][:editable]&.to_boolean
  end

  def fields
    @fields ||= (params[:fields] || ActionController::Parameters.new({})).to_unsafe_h
                  .transform_values { |fields| fields.split(',').map { |field| field.camelize(:lower).to_sym } }
                  .with_indifferent_access
  end

  def filter
    return @filter if defined?(@filter)
    filter_params = transformed_filter_values.except(*SPECIAL_FILTER_FIELDS)
    filter_params['gender'] = prepare_gender(filter_params['gender']) if filter_params.has_key?('gender')
    BOOLEAN_FILTER_ATTRIBUTES.each { |attr| filter_params[attr] = filter_params[attr].to_boolean if filter_params[attr] }
    @filter = filter_params.to_h.with_indifferent_access
  end

  def include
    @include ||= params[:include].to_s.split(",").map(&:underscore)
  end

  def original_params
    params
  end

  def search
    params[:filter] && params[:filter][:search].presence
  end

  def sort
    @sort ||= sort_hash.reject {|field, _| permitted_query.exclude?(field)}.with_indifferent_access
  end

  def sort_text
    sort.map { |field, direction| "#{field} #{direction}" }.join(',')
  end

  def method_missing(method)
    params[method]
  end

  private

  attr_reader :params, :permitted, :permitted_query

  def transformed_filter_values
    permitted_filter_params.transform_values do |list|
      items = list.to_s.split(',')
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
    # ActionController::Parameters#permit will strip out any key whose value is an Array,
    # so first convert any Arrays to comma-separated lists
    params[:filter]&.each { |k,v| params[:filter][k] = v.join(',') if v.is_a?(Array) }
    permitted_keys = permitted_query << :editable
    params[:filter]&.permit(*permitted_keys) || {}
  end

  def sort_fields
    params[:sort].to_s.split(',')
  end
end
