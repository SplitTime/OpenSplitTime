# frozen_string_literal: true

module RefreshHelper
  def link_to_refresh
    link_to fa_icon(:redo), request.params, class: 'btn btn-primary'
  end
end
