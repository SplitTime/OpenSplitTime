# frozen_string_literal: true

class ParticipationNotifier < BaseNotifier
  VERBS = {unstarted: 'will be participating', in_progress: 'is in progress', stopped: 'recently participated'}
  RESULTS_DESCRIPTORS = {unstarted: 'Watch for results', in_progress: 'Follow along', stopped: 'See full results'}

  def post_initialize(args)
    @effort = args[:effort]
  end

  private

  attr_reader :effort
  delegate :event, :person, to: :effort

  def subject
    "#{person.full_name} #{verb} at #{event.name}"
  end

  def message
    <<~MESSAGE
      Your friend #{person.full_name} #{verb} at #{event.name}!
      #{results_descriptor} here: #{ENV['BASE_URI']}/efforts/#{effort.id}
      #{live_update_message}
      Thank you for using OpenSplitTime!
      You are receiving this message because you signed up on OpenSplitTime and asked to follow #{person.first_name}. 
      To change your preferences, go to #{ENV['BASE_URI']}/people/#{person.id}, then log in and click to unfollow.
    MESSAGE
  end

  def verb
    VERBS[effort_status]
  end

  def results_descriptor
    RESULTS_DESCRIPTORS[effort_status]
  end

  def live_update_message
    effort_status == :stopped ? nil : "Click the link and sign in to receive live updates for #{effort.first_name}."
  end

  def effort_status
    case
    when effort.stopped?
      :stopped
    when effort.in_progress?
      :in_progress
    else
      :unstarted
    end
  end
end
