module DataStatusHelper
  STATUS_INDICATOR_ATTRIBUTES = {
    bad: { icon: "circle-xmark", class: "text-danger" },
    questionable: { icon: "circle-question", class: "text-warning" }
  }.with_indifferent_access

  def text_with_status_indicator(time, status, options = {})
    attributes = STATUS_INDICATOR_ATTRIBUTES[status]
    return time if attributes.nil?

    data_type = options[:data_type] || :time
    tooltip_title = "#{data_type} appears #{status}".titleize

    fa_icon(attributes[:icon],
            class: attributes[:class],
            text: time,
            data: { controller: :tooltip, bs_original_title: tooltip_title })
  end
end
