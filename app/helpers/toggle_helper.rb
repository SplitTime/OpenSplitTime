# frozen_string_literal: true

module ToggleHelper
  def link_to_toggle_check_in(effort)
    if effort.beyond_start?
      icon_name = "caret-square-right"
      button_text = "Beyond start"
      url = "#"
      disabled = true
      button_class = "primary"
    elsif effort.started?
      icon_name = "caret-square-right"
      button_text = "Started"
      url = unstart_effort_path(effort)
      disabled = false
      button_class = "primary"
    elsif effort.checked_in?
      icon_name = "check-square"
      button_text = "Checked in"
      url = effort_path(effort, effort: { checked_in: false })
      disabled = false
      button_class = "success"
    else
      icon_name = "square"
      button_text = "Check in"
      url = effort_path(effort, effort: { checked_in: true })
      disabled = false
      button_class = "outline-secondary"
    end

    class_string = "check-in click-spinner btn btn-block btn-#{button_class}"
    options = { method: :patch,
                disabled: disabled,
                class: class_string }
    link_to fa_icon(icon_name, text: button_text, type: :regular), url, options
  end

  def link_to_check_in_all(view_object)
    url = update_all_efforts_event_group_path(view_object.event_group, efforts: { checked_in: true }, button: :check_in_all)
    options = { method: "patch",
                data: { confirm: "This will check in all entrants, making them eligible to start. Do you want to proceed?",
                        "bs-toggle": :tooltip, placement: :bottom, "original-title" => "Check in all" },
                class: "btn btn-success has-tooltip click-spinner" }
    link_to fa_icon("check-square", text: "All", type: :regular), url, options
  end

  def link_to_check_out_all(view_object)
    url = update_all_efforts_event_group_path(view_object.event_group, efforts: { checked_in: false }, button: :check_out_all)
    options = { method: "patch",
                data: { confirm: "This will check out all unstarted entrants, making them ineligible to start. Do you want to proceed?",
                        "bs-toggle": :tooltip, placement: :bottom, "original-title" => "Check out all" },
                class: "btn btn-outline-secondary has-tooltip click-spinner" }
    link_to fa_icon("square", text: "All", type: :regular), url, options
  end

  def link_to_subscription(subscribable, protocol)
    protocol = protocol.to_s
    raise ArgumentError, "Improper protocol: #{protocol}" unless protocol.in?(%w[email sms])

    update_type = case subscribable.class.name
                  when "Effort"
                    "live progress"
                  when "Person"
                    "future event sign-up"
                  else
                    raise ArgumentError, "Unknown subscribable class: #{subscribable.class.name}"
                  end

    args = case protocol
           when "email"
             { icon_name: "envelope",
               subscribe_alert: "Receive #{update_type} updates for #{subscribable.full_name}? " +
                 "(You will need to click a link in a confirmation email that will be sent to you " +
                 "from AWS Notifications.)",
               unsubscribe_alert: "Stop receiving #{update_type} updates for #{subscribable.full_name}?" }
           when "sms"
             { icon_name: "mobile-alt",
               subscribe_alert: "Receive #{update_type} updates for #{subscribable.full_name}?",
               unsubscribe_alert: "Stop receiving #{update_type} updates for #{subscribable.full_name}?" }
           else
             {}
           end

    if subscribable.topic_resource_key.present?
      args.merge!(subscribable: subscribable, protocol: protocol)
      if current_user
        link_to_toggle_subscription(args)
      else
        link_to_sign_in(args)
      end
    end
  end

  def link_to_toggle_subscription(args)
    subscribable = args[:subscribable]
    icon_name = args[:icon_name]
    protocol = args[:protocol]
    subscribe_alert = args[:subscribe_alert]
    unsubscribe_alert = args[:unsubscribe_alert]
    existing_subscription = subscribable.subscriptions.find_by(user: current_user, protocol: protocol)

    if existing_subscription
      url = polymorphic_path([subscribable, existing_subscription])
      options = { method: "delete",
                  class: "#{protocol}-sub btn btn-lg btn-primary click-spinner",
                  data: { confirm: unsubscribe_alert } }
    else
      url = polymorphic_path([subscribable, :subscriptions], subscription: { protocol: protocol })
      options = { method: "post",
                  class: "#{protocol}-sub btn btn-lg btn-outline-secondary click-spinner",
                  data: { confirm: subscribe_alert } }
    end

    link_to fa_icon(icon_name, text: protocol), url, options
  end

  def link_to_sign_in(args)
    icon_name = args[:icon_name]
    protocol = args[:protocol]
    link_to fa_icon(icon_name, text: " #{protocol}"), "#", class: "btn btn-lg btn-outline-secondary", data: { "bs-toggle": "modal", "bs-target": "#log-in-modal" }
  end
end
