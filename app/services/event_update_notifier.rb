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
      default: "#{event.slug} (#{event.id}) was updated at #{event.updated_at}",
      http: http_message,
      https: http_message,
    }.to_json
  end

  # http_message has to be converted to JSON individually and then wrapped in JSON again within the message method
  def http_message
    {
      data: {
        type: "events",
        id: event.id,
        attributes: {
          updated_at: event.updated_at,
        }
      }
    }.to_json
  end
end
