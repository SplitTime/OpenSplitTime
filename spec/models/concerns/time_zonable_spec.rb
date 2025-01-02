require "rails_helper"

RSpec.describe TimeZonable do
  let(:dummy_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include TimeZonable

      attribute :start_time, :datetime
      attribute :finish_time, :datetime

      zonable_attributes :start_time, :finish_time

      def home_time_zone; end
    end
  end

  describe "getter and setter methods" do
    let(:dummy_instance) { dummy_class.new }
    let(:start_time_local) { "2023-05-05 08:30:40" }
    let(:finish_time_local) { "2023-05-05 10:30:40" }

    before { allow_any_instance_of(dummy_class).to receive(:home_time_zone).and_return(home_time_zone) }

    context "when home_time_zone is available and valid" do
      let(:home_time_zone) { "Mountain Time (US & Canada)" }

      before do
        dummy_instance.start_time_local = start_time_local
        dummy_instance.finish_time_local = finish_time_local
      end

      it "defines getter and setter methods for each zonable attribute" do
        expect(dummy_instance.start_time_local).to eq(start_time_local.in_time_zone(home_time_zone))
        expect(dummy_instance.finish_time_local).to eq(finish_time_local.in_time_zone(home_time_zone))
      end

      context "when time provided is nil" do
        it "sets the attribute to nil" do
          dummy_instance.start_time_local = start_time_local
          expect(dummy_instance.start_time).not_to be_nil
          dummy_instance.start_time_local = nil
          expect(dummy_instance.start_time).to be_nil
        end
      end

      context "when time provided is blank" do
        it "sets the attribute to nil" do
          dummy_instance.start_time_local = start_time_local
          expect(dummy_instance.start_time).not_to be_nil
          dummy_instance.start_time_local = ""
          expect(dummy_instance.start_time).to be_nil
        end
      end

      context "when the time provided is not a valid datetime" do
        let(:start_time_local) { "invalid" }

        it "sets the persisted attribute to nil" do
          expect(dummy_instance.start_time).to be_nil
        end
      end

      context "when the time provided is an unformatted datetime" do
        let(:start_time_local) { "10072017 060000" }

        it "sets the persisted attribute to nil" do
          expect(dummy_instance.start_time).to be_nil
        end
      end

      context "when the time provided is an incomplete masked datetime" do
        let(:start_time_local) { "10/07/20yy hh:mm:ss" }

        it "sets the persisted attribute to nil" do
          expect(dummy_instance.start_time).to be_nil
        end
      end
    end

    context "when home_time_zone is not available" do
      let(:home_time_zone) { nil }

      it "raises an error" do
        expect { dummy_instance.start_time_local = start_time_local }.to raise_error(ArgumentError)
        expect { dummy_instance.finish_time_local = finish_time_local }.to raise_error(ArgumentError)
      end
    end

    context "when home_time_zone is not valid" do
      let(:home_time_zone) { "invalid" }

      it "raises an error" do
        expect { dummy_instance.start_time_local = start_time_local }.to raise_error(ArgumentError)
        expect { dummy_instance.finish_time_local = finish_time_local }.to raise_error(ArgumentError)
      end
    end
  end
end
