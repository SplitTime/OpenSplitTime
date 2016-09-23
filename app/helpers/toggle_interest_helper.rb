module ToggleInterestHelper

  def link_to_toggle_interest(participant)

    if @current_user && @current_user.interested_in?(participant)
      url = current_user_unfollow_participant_path(participant)
      link_to_with_icon('glyphicon glyphicon-ok', 'Following', url, {
          method: 'post',
          remote: true,
          class: 'interest btn btn-xs btn-success',
      })
    else
      url = current_user_follow_participant_path(participant)
      link_to_with_icon('glyphicon glyphicon-star-empty', 'Interested', url, {
          method: 'post',
          remote: true,
          class: 'interest btn btn-xs btn-default',
      })
    end
  end

  def link_to_with_icon(icon_css, title, url, options = {})
    icon = content_tag(:i, nil, class: icon_css)
    title_with_icon = icon << ' '.html_safe << h(title)
    link_to(title_with_icon, url, options)
  end

end