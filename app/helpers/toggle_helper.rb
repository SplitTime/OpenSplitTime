# frozen_string_literal: true

module ToggleHelper
  def link_to_check_in_filters(icon_name, text, checked_in, started, unreconciled, problem)
    url = request.params.merge(checked_in: checked_in, started: started, unreconciled: unreconciled, problem: problem, filter: {search: ''}, page: nil)
    disabled = params[:checked_in]&.to_boolean == checked_in && params[:started]&.to_boolean == started &&
        params[:unreconciled]&.to_boolean == unreconciled && params[:problem]&.to_boolean == problem
    options = {class: 'btn btn-md btn-primary', disabled: disabled}
    link_to fa_icon(icon_name, text: text), url, options
  end

  def link_to_raw_time_filters(icon_name, text, stopped, pulled, matched)
    url = request.params.merge(stopped: stopped, pulled: pulled, matched: matched, filter: {search: ''}, page: nil)
    disabled = params[:stopped]&.to_boolean == stopped && params[:pulled]&.to_boolean == pulled && params[:matched]&.to_boolean == matched
    options = {class: 'btn btn-md btn-primary', disabled: disabled}
    link_to fa_icon(icon_name, text: text), url, options
  end

  def link_to_toggle_check_in(effort, button_param: :check_in_group, block: true)
    block_string = block ? 'btn-block' : ''
    case
    when effort.beyond_start?
      icon_name = 'caret-square-right'
      button_text = 'Beyond start'
      url = '#'
      disabled = true
      button_class = "primary"
    when effort.started?
      icon_name = 'caret-square-right'
      button_text = 'Started'
      url = unstart_effort_path(effort, button: button_param)
      disabled = false
      button_class = "primary"
    when effort.checked_in?
      icon_name = 'check-square'
      button_text = 'Checked in'
      url = effort_path(effort, effort: {checked_in: false}, button: button_param)
      disabled = false
      button_class = "success"
    else
      icon_name = 'square'
      button_text = 'Check in'
      url = effort_path(effort, effort: {checked_in: true}, button: button_param)
      disabled = false
      button_class = "outline-secondary"
    end

    class_string = "check-in click-spinner btn btn-#{button_class} #{block_string}"
    options = {method: :patch,
               remote: true,
               disabled: disabled,
               class: class_string}
    link_to fa_icon(icon_name, text: button_text, type: :regular), url, options
  end

  def link_to_check_in_all(view_object)
    url = update_all_efforts_event_group_path(view_object.event_group, efforts: {checked_in: true}, button: :check_in_all)
    options = {method: 'patch',
               data: {confirm: 'This will check in all entrants, making them eligible to start. Do you want to proceed?',
                      toggle: :tooltip, placement: :bottom, 'original-title' => 'Check in all'},
               class: 'btn btn-success has-tooltip click-spinner'}
    link_to fa_icon('check-square', text: 'All', type: :regular), url, options
  end

  def link_to_check_out_all(view_object)
    url = update_all_efforts_event_group_path(view_object.event_group, efforts: {checked_in: false}, button: :check_out_all)
    options = {method: 'patch',
               data: {confirm: 'This will check out all unstarted entrants, making them ineligible to start. Do you want to proceed?',
                      toggle: :tooltip, placement: :bottom, 'original-title' => 'Check out all'},
               class: 'btn btn-outline-secondary has-tooltip click-spinner'}
    link_to fa_icon('square', text: 'All', type: :regular), url, options
  end

  def link_to_toggle_email_subscription(person)
    if current_user
      link_to_toggle_subscription(person_id: person.id,
                                  icon_name: 'envelope',
                                  protocol: 'email',
                                  subscribe_alert: "Receive live email updates for #{person.full_name}? " +
                                      "(You will need to click a link in a confirmation email that will be sent to you " +
                                      "from AWS Notifications.)",
                                  unsubscribe_alert: "Stop receiving live email updates for #{person.full_name}?")
    else
      link_to_sign_in(icon_name: 'envelope', protocol: 'email')
    end
  end

  def link_to_toggle_sms_subscription(person)
    if current_user
      link_to_toggle_subscription(person_id: person.id,
                                  icon_name: 'mobile-alt',
                                  protocol: 'sms',
                                  subscribe_alert: "Receive live text message updates for #{person.full_name}?",
                                  unsubscribe_alert: "Stop receiving live text message updates for #{person.full_name}?")
    else
      link_to_sign_in(icon_name: 'mobile-alt', protocol: 'sms')
    end
  end

  def link_to_toggle_subscription(args)
    person_id = args[:person_id]
    icon_name = args[:icon_name]
    protocol = args[:protocol]
    subscribe_alert = args[:subscribe_alert]
    unsubscribe_alert = args[:unsubscribe_alert]
    subscription = current_user&.subscriptions&.find { |sub| (sub.person_id == person_id) && (sub.protocol == protocol) }

    if subscription
      url = subscription_path(subscription)
      options = {method: 'delete',
                 remote: true,
                 class: "#{protocol}-sub btn btn-lg btn-primary",
                 data: {confirm: unsubscribe_alert}}
      link_to fa_icon(icon_name), url, options

    else
      url = subscriptions_path(subscription: {user_id: current_user&.id, person_id: person_id, protocol: protocol})
      options = {method: 'post',
                 remote: true,
                 class: "#{protocol}-sub btn btn-lg text-dark",
                 data: {confirm: subscribe_alert}}
      link_to fa_icon(icon_name), url, options
    end
  end

  def link_to_sign_in(args)
    icon_name = args[:icon_name]
    url = new_user_session_path(redirect_to: request.fullpath)
    link_to fa_icon(icon_name), url, class: "btn btn-lg text-dark"
  end
end
