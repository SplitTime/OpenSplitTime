require "rails_helper"

RSpec.describe ReconcileSmsCarrierOptOutsJob, type: :job do
  before { allow(AwsSmsClient).to receive(:opted_out_at_by_phone).and_return(aws_opted_out) }

  describe "#perform" do
    context "when AWS and DB agree (no drift)" do
      let(:aws_opted_out) { {} }
      let!(:user) { create(:user, phone: "+12025551212", phone_confirmed_at: Time.current) }

      it "does not raise and does not change user state" do
        expect { described_class.perform_now }.not_to raise_error
        expect(user.reload.sms_carrier_opted_out_at).to be_nil
      end
    end

    context "when AWS lists a user opted out but DB has them as not-opted-out (Direction 1)" do
      let(:historical_opt_out_at) { Time.zone.parse("2017-07-14T21:34:39Z") }
      let(:aws_opted_out) { { "+12025551212" => historical_opt_out_at } }
      let!(:user) { create(:user, phone: "+12025551212", phone_confirmed_at: Time.current) }

      it "raises SmsReconciliationDriftError" do
        expect { described_class.perform_now }.to raise_error(SmsReconciliationDriftError, /1 correction/)
      end

      it "sets sms_carrier_opted_out_at on the user using the AWS-reported timestamp (not Time.current)" do
        begin
          described_class.perform_now
        rescue SmsReconciliationDriftError
          # expected
        end
        expect(user.reload.sms_carrier_opted_out_at).to be_within(1.second).of(historical_opt_out_at)
      end

      it "includes the user_id in the error message" do
        expect { described_class.perform_now }.to raise_error(SmsReconciliationDriftError, /#{user.id}/)
      end
    end

    context "when DB has a user opted out but AWS no longer lists them (Direction 2)" do
      let(:aws_opted_out) { {} }
      let!(:user) do
        create(:user,
               phone: "+12025551212",
               phone_confirmed_at: Time.current,
               sms_carrier_opted_out_at: 2.days.ago)
      end

      it "raises SmsReconciliationDriftError" do
        expect { described_class.perform_now }.to raise_error(SmsReconciliationDriftError)
      end

      it "clears sms_carrier_opted_out_at on the user before raising" do
        begin
          described_class.perform_now
        rescue SmsReconciliationDriftError
          # expected
        end
        expect(user.reload.sms_carrier_opted_out_at).to be_nil
      end
    end

    context "when both drift directions occur in the same run" do
      let(:opt_out_at) { 1.year.ago }
      let(:aws_opted_out) { { "+12025551212" => opt_out_at } }
      let!(:should_be_opted_out) { create(:user, phone: "+12025551212", phone_confirmed_at: Time.current) }
      let!(:should_be_opted_in) do
        create(:user,
               phone: "+13035551212",
               phone_confirmed_at: Time.current,
               sms_carrier_opted_out_at: 2.days.ago)
      end

      it "raises SmsReconciliationDriftError reporting 2 corrections" do
        expect { described_class.perform_now }.to raise_error(SmsReconciliationDriftError, /2 correction/)
      end

      it "applies both corrections before raising" do
        begin
          described_class.perform_now
        rescue SmsReconciliationDriftError
          # expected
        end
        expect(should_be_opted_out.reload.sms_carrier_opted_out_at).to be_within(1.second).of(opt_out_at)
        expect(should_be_opted_in.reload.sms_carrier_opted_out_at).to be_nil
      end
    end

    context "when the job runs twice in succession with the same AWS state" do
      let(:aws_opted_out) { { "+12025551212" => 1.year.ago } }

      before { create(:user, phone: "+12025551212", phone_confirmed_at: Time.current) }

      it "raises on the first run but not the second (idempotency)" do
        expect { described_class.perform_now }.to raise_error(SmsReconciliationDriftError)
        expect { described_class.perform_now }.not_to raise_error
      end
    end
  end
end
