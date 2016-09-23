module ParticipantsHelper

  def link_to_toggle_interest(participant)
    url = toggle_follower_participant_path(participant)

    if @current_user && @current_user.interested_in?(participant)
      link_to_with_icon('glyphicon glyphicon-ok', 'Following', url, {
          method: 'post',
          remote: true,
          class: 'interest btn btn-xs btn-success',
      })
    else
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