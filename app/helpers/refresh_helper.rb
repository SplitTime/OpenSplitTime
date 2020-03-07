# frozen_string_literal: true

module RefreshHelper
  def link_to_refresh
    tooltip_title = 'Refresh page [CTRL-R]'
    content_tag(:span, data: {controller: :refresh}) do
      link_to fa_icon(:redo, data: {target: 'refresh.icon'}),
              request.params,
              id: 'refresh-button',
              class: 'btn btn-primary has-tooltip',
              data: {action: 'click->refresh#spin keyup@document->refresh#evaluate',
                     target: 'refresh.button',
                     toggle: 'tooltip',
                     placement: :bottom,
                     'original-title' => tooltip_title}
    end
  end
end
