module ToggleSubscriptionHelper

  def link_to_toggle_email_subscription(participant)
    return nil unless @current_user

    subscription = @current_user.subscriptions.find_by(participant_id: participant.id, protocol: 'email')
    if subscription
      url = subscription_path(subscription)
      link_to_with_icon('glyphicon glyphicon-envelope', 'Subscribed', url, {
          method: 'delete',
          remote: true,
          class: 'email-sub btn btn-xs btn-success',
          data: {confirm: "Are you sure you want to stop receiving live email updates for #{participant.full_name}?"}
      })
    else
      url = subscriptions_path(subscription: {user_id: @current_user.id,
                                              participant_id: participant.id,
                                              protocol: 'email'})
      link_to_with_icon('glyphicon glyphicon-envelope', 'Notify', url, {
          method: 'post',
          remote: true,
          class: 'email-sub btn btn-xs btn-default',
          data: {confirm: "Before you start receiving live email updates for #{participant.full_name}, " +
              "you may need to confirm an email sent to you from AWS. Do you want to proceed?"}
      })
    end
  end

  def link_to_with_icon(icon_css, title, url, options = {})
    icon = content_tag(:i, nil, class: icon_css)
    title_with_icon = icon << ' '.html_safe << h(title)
    link_to(title_with_icon, url, options)
  end
end