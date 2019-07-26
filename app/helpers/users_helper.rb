# frozen_string_literal: true

module UsersHelper
  def link_to_delete_user(user)
    url = user_path(user, referrer_path: request.params)
    options = {method: :delete,
               data: {confirm: 'This cannot be undone. Are you sure you want to delete this record?',
                      toggle: :tooltip,
                      placement: :bottom,
                      'original-title' => 'Delete user'},
               class: 'btn btn-danger has-tooltip'}
    link_to fa_icon('trash'), url, options
  end

  def link_to_become_user(user)
    url = admin_impersonate_path(user)
    options = {method: :post, class: 'btn btn-warning has-tooltip'}
    link_to fa_icon('theater-masks'), url, options
  end
end
