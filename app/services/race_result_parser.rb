class RaceResultParser

  def initialize(args)
    ArgsValidator.validate(params: args, required: [:event, :json_response],
                           exclusive: [:event, :json_response, :builder], class: self.class)
    @event = args[:event]
    @json_response = args[:json_response]
    validate_setup
  end

  def parse

  end

  private

  attr_reader :event, :json_response

  def validate_setup
    errors << split_mismatch_error unless response_fields.size == ordered_splits.size - 1
  end

  def split_mismatch_error
    {title: 'Split mismatch error', detail: {messages: ["Event has "]}}
  end
end
