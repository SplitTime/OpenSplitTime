class PreparedParams
  SPECIAL_FILTER_FIELDS = %i[editable search].freeze
  BOOLEAN_FILTER_ATTRIBUTES = %i[ready_to_start].freeze
  FIRST_PAGE = 1

  def initialize(params, permitted, permitted_query = nil)
    @params = params
    @permitted = (permitted || []).map { |attr| attr.is_a?(Symbol) ? attr.to_s : attr }
    @permitted_query = (permitted_query || @permitted).map(&:to_s)
  end

  def [](method_name)
    send(method_name)
  end

  def data
    @data ||= params.require(:data).require(:attributes).permit(permitted)
  rescue ::ActionController::ParameterMissing
    {}
  end

  def editable
    filter_hash = params[:filter]
    return nil unless filter_hash.is_a?(ActionController::Parameters) || filter_hash.is_a?(Hash)

    filter_hash[:editable]&.to_boolean
  end

  def fields
    raw_fields = (params[:fields] || ActionController::Parameters.new({})).to_unsafe_h
    @fields ||= raw_fields.transform_values { |fields| fields.split(",").map { |field| field.camelize(:lower).to_sym } }
                          .with_indifferent_access
  end

  def filter
    return @filter if defined?(@filter)

    filter_params = transformed_filter_values.except(*SPECIAL_FILTER_FIELDS)
    filter_params["gender"] = prepare_gender(filter_params["gender"]) if filter_params.key?("gender")
    BOOLEAN_FILTER_ATTRIBUTES.each do |attr|
      filter_params[attr] = filter_params[attr].to_boolean if filter_params[attr]
    end
    @filter = filter_params.to_h.with_indifferent_access
  end

  def include
    @include ||= params[:include].to_s.split(",").map(&:underscore)
  end

  def original_params
    params
  end

  def page
    result = params[:page]&.to_i || FIRST_PAGE
    result.zero? ? FIRST_PAGE : result
  end

  def search
    filter_hash = params[:filter]
    return nil unless filter_hash.is_a?(ActionController::Parameters) || filter_hash.is_a?(Hash)

    filter_hash[:search].presence
  end

  def sort
    @sort ||= sort_hash.slice(*permitted_query).with_indifferent_access
  end

  def sort_text
    sort.map { |field, direction| "#{field} #{direction}" }.join(",")
  end

  def method_missing(method, ...)
    params[method]
  end

  def respond_to_missing?(method, include_private = false)
    params.key?(method) || super
  end

  private

  attr_reader :params, :permitted, :permitted_query

  def transformed_filter_values
    permitted_filter_params.transform_values do |list|
      items = list.to_s.split(",")
      items.size > 1 ? items : items.first.presence
    end
  end

  def prepare_gender(gender_params)
    gender_enums = Array.wrap(gender_params).map { |param| param.numeric? ? param.to_i : Effort.genders[param] }
    gender_enums.compact.presence || Effort.genders.values
  end

  def sort_hash
    sort_fields.each_with_object({}) do |field, hash|
      if field.start_with?("-")
        hash[field[1..].underscore] = :desc
      else
        hash[field.underscore] = :asc
      end
    end
  end

  def permitted_filter_params
    filter_hash = params[:filter]
    return {} unless filter_hash.is_a?(ActionController::Parameters)

    # ActionController::Parameters#permit will strip out any key whose value is an Array,
    # so first convert any Arrays to comma-separated lists
    filter_hash.each { |k, v| filter_hash[k] = v.join(",") if v.is_a?(Array) }
    permitted_keys = permitted_query << :editable
    filter_hash.permit(*permitted_keys)
  end

  def sort_fields
    params[:sort].to_s.split(",")
  end
end
