# frozen_string_literal: true

module RefreshHelper
  def link_to_refresh
    tooltip_title = 'Refresh [Ctrl-R]'
    content_tag(:span, data: {controller: 'navigation animation'}) do
      link_to fa_icon(:redo),
              request.params,
              id: 'refresh-button',
              class: 'btn btn-primary has-tooltip',
              data: {action: 'click->animation#spinIcon keyup@document->navigation#evaluateKeyup',
                     target: 'navigation.refreshButton',
                     toggle: 'tooltip',
                     placement: :bottom,
                     'original-title' => tooltip_title}
    end
  end
end
