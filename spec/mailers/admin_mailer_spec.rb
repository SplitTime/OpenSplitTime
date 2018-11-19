# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminMailer, type: :mailer do
  include ActiveJob::TestHelper
  let(:user){ create(:user) }
  let(:event) { create(:event) }

  it 'creates a job' do
    expect { AdminMailer.new_event(event, user).deliver_later }.to have_enqueued_job.on_queue('mailers')
  end

  # Because we have config.action_mailer.delivery_method set to :test in our :test.rb,
  # all 'sent' emails are gathered into the ActionMailer::Base.deliveries array.

  it 'sends an email' do
    expect {
      perform_enqueued_jobs do
        AdminMailer.new_event(event, user).deliver_later
      end
    }.to change { ActionMailer::Base.deliveries.size }.by(1)
  end

  it 'sends email to the correct admin' do
    perform_enqueued_jobs do
      AdminMailer.new_event(event, user).deliver_later
    end

    mail = ActionMailer::Base.deliveries.last
    expect(mail.to[0]).to eq ENV['ADMIN_EMAIL']
  end
end
