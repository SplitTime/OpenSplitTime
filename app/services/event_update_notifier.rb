# frozen_string_literal: true

class EventUpdateNotifier < BaseNotifier
  def post_initialize(args)
    @event = args[:event]
  end

  def publish
    sns_response = sns_client.publish(
      topic_arn: topic_arn,
      subject: subject,
      message: message,
      message_structure: "json"
    )
    Interactors::Response.new([], "Published", response: sns_response, subject: subject, notice_text: message)
  rescue Aws::SNS::Errors::ServiceError => e
    Interactors::Response.new([aws_sns_error(e)], e.message, {})
  end

  private

  attr_reader :event

  def subject
    "Update for #{event.name} from OpenSplitTime"
  end

  def message
    {
      default: "#{event.name} has been updated as of #{event.updated_at}.",
      http: http_message,
      https: http_message,
    }.to_json
  end

  def http_message
    {
      data: {
        event: {
          id: event.id,
          updated_at: event.updated_at,
        }
      }
    }
  end
end
