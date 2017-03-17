module ToggleSubscriptionHelper

  def link_to_toggle_email_subscription(participant)
    if @current_user
      link_to_toggle_subscription(participant: participant,
                                  glyphicon: 'envelope',
                                  protocol: 'email',
                                  subscribe_alert: "Receive live email updates for #{participant.full_name}? " +
                                      "(You will need to click a link in a confirmation email that will be sent to you " +
                                      "from AWS Notifications.)",
                                  unsubscribe_alert: "Stop receiving live email updates for #{participant.full_name}?")
    else
      link_to_sign_in(glyphicon: 'envelope', protocol: 'email')
    end
  end

  def link_to_toggle_sms_subscription(participant)
    if @current_user
      link_to_toggle_subscription(participant: participant,
                                  glyphicon: 'phone',
                                  protocol: 'sms',
                                  subscribe_alert: "Receive live text message updates for #{participant.full_name}?",
                                  unsubscribe_alert: "Stop receiving live text message updates for #{participant.full_name}?")
    else
      link_to_sign_in(glyphicon: 'phone', protocol: 'sms')
    end
  end

  def link_to_toggle_subscription(args)
    participant = args[:participant]
    glyphicon = args[:glyphicon]
    protocol = args[:protocol]
    subscribe_alert = args[:subscribe_alert]
    unsubscribe_alert = args[:unsubscribe_alert]
    subscription = @current_user.subscriptions
                       .find { |sub| (sub.participant_id == participant.id) && (sub.protocol == protocol) }

    if subscription
      url = subscription_path(subscription)
      link_to_with_icon("glyphicon glyphicon-#{glyphicon}", 'Subscribed', url, {
          method: 'delete',
          remote: true,
          class: "#{protocol}-sub btn btn-xs btn-success",
          data: {confirm: unsubscribe_alert}
      })
    else
      url = subscriptions_path(subscription: {user_id: @current_user.id,
                                              participant_id: participant.id,
                                              protocol: protocol})
      link_to_with_icon("glyphicon glyphicon-#{glyphicon}", 'Notify', url, {
          method: 'post',
          remote: true,
          class: "#{protocol}-sub btn btn-xs btn-default",
          data: {confirm: subscribe_alert}
      })
    end
  end

  def link_to_sign_in(args)
    glyphicon = args[:glyphicon]
    protocol = args[:protocol]

    url = subscriptions_path
    link_to_with_icon("glyphicon glyphicon-#{glyphicon}", 'Notify', url, {
        method: 'post',
        remote: true,
        class: "#{protocol}-sub btn btn-xs btn-default"
    })
  end

  def link_to_with_icon(icon_css, title, url, options = {})
    icon = content_tag(:i, nil, class: icon_css)
    title_with_icon = icon << ' '.html_safe << h(title)
    link_to(title_with_icon, url, options)
  end
end