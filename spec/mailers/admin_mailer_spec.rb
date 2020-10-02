# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminMailer, type: :mailer do
  include ActiveJob::TestHelper

  subject { AdminMailer.new_event_group(event_group) }
  let(:event_group) { event_groups(:sum) }

  it 'creates a job' do
    expect { subject.deliver_later }.to have_enqueued_job.on_queue('mailers')
  end

  # Because we have config.action_mailer.delivery_method set to :test in our :test.rb,
  # all 'sent' emails are gathered into the ActionMailer::Base.deliveries array.
  it 'sends an email' do
    expect {
      perform_enqueued_jobs { subject.deliver_later }
    }.to change { ActionMailer::Base.deliveries.size }.by(1)
  end

  it 'sends email to the correct admin' do
    perform_enqueued_jobs { subject.deliver_later }

    mail = ActionMailer::Base.deliveries.last
    expect(mail.to[0]).to eq ENV['ADMIN_EMAIL']
  end
end
