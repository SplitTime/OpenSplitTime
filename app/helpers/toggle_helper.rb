module ToggleHelper

  def link_to_toggle_check_in(effort)
    if effort.checked_in?
      url = effort_path(effort, effort: {checked_in: false}, button: :check_in)
      link_to_with_icon("glyphicon glyphicon-check", 'Checked', url, {
          method: 'patch',
          remote: true,
          class: "check-in btn btn-sm btn-success"
      })
    else
      url = effort_path(effort, effort: {checked_in: true}, button: :check_in)
      link_to_with_icon("glyphicon glyphicon-unchecked", 'Check In', url, {
          method: 'patch',
          remote: true,
          class: "check-in btn btn-sm btn-default"
      })
    end
  end

  def link_to_toggle_email_subscription(person)
    if @current_user
      link_to_toggle_subscription(person: person,
                                  glyphicon: 'envelope',
                                  protocol: 'email',
                                  subscribe_alert: "Receive live email updates for #{person.full_name}? " +
                                      "(You will need to click a link in a confirmation email that will be sent to you " +
                                      "from AWS Notifications.)",
                                  unsubscribe_alert: "Stop receiving live email updates for #{person.full_name}?")
    else
      link_to_sign_in(glyphicon: 'envelope', protocol: 'email')
    end
  end

  def link_to_toggle_sms_subscription(person)
    if @current_user
      link_to_toggle_subscription(person: person,
                                  glyphicon: 'phone',
                                  protocol: 'sms',
                                  subscribe_alert: "Receive live text message updates for #{person.full_name}?",
                                  unsubscribe_alert: "Stop receiving live text message updates for #{person.full_name}?")
    else
      link_to_sign_in(glyphicon: 'phone', protocol: 'sms')
    end
  end

  def link_to_toggle_subscription(args)
    person = args[:person]
    glyphicon = args[:glyphicon]
    protocol = args[:protocol]
    subscribe_alert = args[:subscribe_alert]
    unsubscribe_alert = args[:unsubscribe_alert]
    subscription = @current_user.subscriptions
                       .find { |sub| (sub.person_id == person.id) && (sub.protocol == protocol) }

    if subscription
      url = subscription_path(subscription)
      link_to_with_icon("glyphicon glyphicon-#{glyphicon}", protocol, url, {
          method: 'delete',
          remote: true,
          class: "#{protocol}-sub btn btn-xs btn-success",
          data: {confirm: unsubscribe_alert}
      })
    else
      url = subscriptions_path(subscription: {user_id: @current_user.id,
                                              person_id: person.id,
                                              protocol: protocol})
      link_to_with_icon("glyphicon glyphicon-#{glyphicon}", protocol, url, {
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
    link_to_with_icon("glyphicon glyphicon-#{glyphicon}", protocol, url, {
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