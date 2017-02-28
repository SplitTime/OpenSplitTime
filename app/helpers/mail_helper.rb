module MailHelper

  def follower_update_body_text(split_time_data)
    "#{split_time_data[:split_name]} at #{split_time_data[:day_and_time]} " +
    "#{split_time_data[:pacer] ? 'with a pacer ' : ''}" +
    "#{split_time_data[:stopped_here] ? 'and stopped there' : ''}"
  end
end