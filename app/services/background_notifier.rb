class BackgroundNotifier

  PASS_THROUGH_ATTRIBUTES = %i(current_object total_objects action resource)
  PREPARED_ATTRIBUTES = %i(message progress)

  def self.publish(args)
    new(args).publish
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:channel, :event],
                           class: self.class)
    @channel = args[:channel]
    @event = args[:event]
    @message_data = args.except(:channel, :event).with_indifferent_access
  end

  def publish
    response = Pusher.trigger(channel, event, prepared_data)
    if response
      response
    else
      Rails.logger.info "Unable to publish to #{channel}"
    end
  end

  private

  attr_reader :channel, :event, :message_data

  def prepared_data
    all_attributes.each_with_object({}) do |attribute, hash|
      value = send(attribute)
      hash[attribute] = value if value
    end
  end

  def all_attributes
    PASS_THROUGH_ATTRIBUTES + PREPARED_ATTRIBUTES
  end

  def message
    message_data[:message] || constructed_message
  end

  def constructed_message
    action && resource && current_object && total_objects &&
        "#{action.capitalize} #{current_object} of #{total_objects} #{resource.pluralize}"
  end

  def progress
    current_object && total_objects && (current_object / total_objects.to_f * 100).to_i
  end

  PASS_THROUGH_ATTRIBUTES.each do |attribute|
    define_method(attribute) do
      message_data[attribute]
    end
  end
end
