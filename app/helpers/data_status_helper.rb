# frozen_string_literal: true

STATUS_INDICATOR_ATTRIBUTES = {
  bad: {icon: 'times-circle', class: 'text-danger'},
  questionable: {icon: 'question-circle', class: 'text-warning'},
}.with_indifferent_access

module DataStatusHelper
  def text_with_status_indicator(time, status, options = {})
    attributes = STATUS_INDICATOR_ATTRIBUTES[status]
    return time if attributes.nil?

    data_type = options[:data_type] || :time
    tooltip_title = "#{data_type} appears #{status}".titleize

    fa_icon(attributes[:icon],
            class: ['has-tooltip', attributes[:class]].join(' '),
            text: time,
            data: {toggle: 'tooltip', 'original-title' => tooltip_title})
  end
end
