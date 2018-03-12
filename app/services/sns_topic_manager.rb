# frozen_string_literal: true

class SnsTopicManager

  def self.generate(args)
    new(args).generate
  end

  def self.delete(args)
    new(args).delete
  end

  def initialize(args)
    ArgsValidator.validate(params: args, required: :person, exclusive: [:person, :sns_client], class: self.class)
    @person = args[:person]
    @sns_client = args[:sns_client] || SnsClientFactory.client
  end

  def generate
    response = sns_client.create_topic(name: "#{environment_prefix}follow_#{person.slug}")
    if response.successful?
      print '.' unless Rails.env.test?
      Rails.logger.info "Generated SNS topic for #{person.slug}"
      response.topic_arn.include?('arn:aws:sns') ? response.topic_arn : "#{response.topic_arn}:#{SecureRandom.uuid}"
    else
      print 'X' unless Rails.env.test?
      warn "Unable to generate SNS topic for #{person.slug}"
      nil
    end
  end

  def delete
    if topic_arn && topic_arn.include?('arn:aws:sns')
      response = sns_client.delete_topic(topic_arn: topic_arn)
      if response.successful?
        print '.' unless Rails.env.test?
        Rails.logger.info "Deleted SNS topic #{topic_arn}"
        topic_arn
      else
        print 'X' unless Rails.env.test?
        warn "Unable to delete SNS topic #{topic_arn}"
        nil
      end
    else
      print '-' unless Rails.env.test?
      warn "#{person.slug} has no topic_resource_key or topic_arn does not exist" unless Rails.env.test?
    end
  end

  private

  attr_reader :person, :sns_client

  def topic_arn
    person.topic_resource_key
  end

  def environment_prefix
    @environment_prefix ||= Rails.env.production? ? '' : "#{Rails.env.first}-"
  end
end
