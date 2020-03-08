# frozen_string_literal: true

module NavigationHelper
  def link_to_refresh
    tooltip_title = 'Refresh page [CTRL-R]'
    content_tag(:span, data: {controller: :navigation}) do
      link_to fa_icon(:redo),
              request.params,
              id: 'refresh-button',
              class: 'btn btn-primary has-tooltip',
              data: {action: 'click->navigation#spinIcon keyup@document->navigation#evaluateKeyup',
                     target: 'navigation.refreshButton',
                     toggle: 'tooltip',
                     placement: :bottom,
                     'original-title' => tooltip_title}
    end
  end
end
