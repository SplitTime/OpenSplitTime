# frozen_string_literal: true

STATUS_INDICATOR_ATTRIBUTES = {
  bad: {icon: 'times-circle', class: 'text-danger', tooltip_title: 'Time Appears Bad'},
  questionable: {icon: 'question-circle', class: 'text-warning', tooltip_title: 'Time Appears Questionable'},
}.with_indifferent_access

module TimeStatusHelper
  def time_with_status_indicator(time, status)
    attributes = STATUS_INDICATOR_ATTRIBUTES[status]
    return time if attributes.nil?

    fa_icon(attributes[:icon],
            class: ['has-tooltip', attributes[:class]].join(' '),
            text: time,
            data: {toggle: 'tooltip', 'original-title' => attributes[:tooltip_title]})
  end
end
