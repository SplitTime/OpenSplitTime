class SnsTopicManager

  def self.generate(args)
    new(args).generate
  end

  def self.delete(args)
    new(args).delete
  end

  def initialize(args)
    ArgsValidator.validate(params: args, required: :participant, exclusive: [:participant, :sns_client], class: self.class)
    @participant = args[:participant]
    @sns_client = args[:sns_client] || SnsClientFactory.client
  end

  def generate
    response = sns_client.create_topic(name: "#{environment_prefix}follow_#{participant.slug}")
    if response.successful?
      print '.'
      Rails.logger.info "Generated SNS topic for #{participant.slug}"
      response.topic_arn.include?('arn:aws:sns') ? response.topic_arn : "#{response.topic_arn}:#{SecureRandom.uuid}"
    else
      print 'X'
      Rails.logger.info "Unable to generate SNS topic for #{participant.slug}"
      nil
    end
  end

  def delete
    response = sns_client.delete_topic(topic_arn: topic_arn)
    if response.successful?
      print '.'
      Rails.logger.info "Deleted SNS topic #{topic_arn}"
      topic_arn
    else
      print 'X'
      Rails.logger.info "Unable to delete SNS topic #{topic_arn}"
      nil
    end
  end

  private

  attr_reader :participant, :sns_client

  def topic_arn
    participant.topic_resource_key
  end

# TODO Create separate AWS accounts with separate credentials for dev, staging, and production environments
  def environment_prefix
    @environment_prefix ||= Rails.env.production? ? '' : "#{Rails.env.first}-"
  end
end