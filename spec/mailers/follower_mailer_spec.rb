require 'rails_helper'

RSpec.describe FollowerMailer, type: :mailer do
  describe 'instructions' do
    let(:split_times_data) do
      [{time_point: TimePoint.new(1, 101, 1),
        split_name: 'Aid Station In',
        day_and_time: 'Friday, July 1, 2016  7:40AM',
        pacer: nil,
        stopped_here: false},
       {time_point: TimePoint.new(1, 101, 64),
        split_name: 'Aid Station Out',
        day_and_time: 'Friday, July 1, 2016  7:50AM',
        pacer: nil,
        stopped_here: true}]
    end

    let(:effort_data) do
      {full_name: 'Johnny Appleseed',
       event_name: 'Testrock 100',
       split_times_data: split_times_data,
       effort_id: 101,
       event_id: 202}
    end

    let(:user) { FactoryGirl.build(:user, first_name: 'Lucas', email: 'lucas@email.com') }
    let(:mail) { described_class.live_effort_email(user, effort_data).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Update for Johnny Appleseed at Testrock 100 from OpenSplitTime')
    end

    it 'renders the receiver email address' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email address' do
      expect(mail.from).to eq(['no-reply@opensplittime.org'])
    end

    it 'includes the follower first name' do
      expect(mail.body.encoded).to match(user.first_name)
    end

    it 'includes the relevant information in the body of the email' do
      expect(mail.body.encoded).to match(user.first_name)
      expect(mail.body.encoded).to match('The following new times were reported for Johnny Appleseed at Testrock 100')
      expect(mail.body.encoded).to match('Aid Station In at Friday, July 1, 2016  7:40AM')
      expect(mail.body.encoded).to match('Aid Station Out at Friday, July 1, 2016  7:50AM')
      expect(mail.body.encoded).to match('and stopped there')
    end
  end
end