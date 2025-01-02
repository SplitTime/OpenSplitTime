require "rails_helper"

RSpec.describe Etl::Loaders::Async::UltrasignupOrderIdCompareStrategy do
  subject { described_class.new(proto_records, options) }
  let(:options) { { import_job: import_job } }
  let!(:import_job) { create(:import_job, parent: organization, format: :test_format) }
  let(:organization) { organizations(:hardrock) }

  describe "#load_records" do
    context "when all order ids match" do
      let(:proto_records) do
        [
          ProtoRecord.new(
            Order_ID: "123",
            ),
          ProtoRecord.new(
            Order_ID: "456",
            ),
          ProtoRecord.new(
            Order_ID: "789",
            ),
        ]
      end

      it "does not add errors" do
        subject.load_records
        expect(subject.errors).to be_empty
      end
    end

    context "when order ids are integers" do
      let(:proto_records) do
        [
          ProtoRecord.new(
            Order_ID: 123,
          ),
          ProtoRecord.new(
            Order_ID: 456,
          ),
          ProtoRecord.new(
            Order_ID: 789,
          ),
        ]
      end

      it "does not add errors" do
        subject.load_records
        expect(subject.errors).to be_empty
      end
    end

    context "when some order ids are duplicates" do
      let(:proto_records) do
        [
          ProtoRecord.new(
            Order_ID: "123",
            ),
          ProtoRecord.new(
            Order_ID: "456",
            ),
          ProtoRecord.new(
            Order_ID: "456",
            ),
        ]
      end

      it "adds an order id duplicated error" do
        subject.load_records
        expect(subject.errors).to be_present
        expect(subject.errors.first.dig(:detail, :messages).first).to include("456")
      end
    end

    context "when some order ids are missing from OST" do
      let(:proto_records) do
        [
          ProtoRecord.new(
            Order_ID: "123",
          ),
          ProtoRecord.new(
            Order_ID: "456",
          ),
          ProtoRecord.new(
            Order_ID: "789",
          ),
          ProtoRecord.new(
            Order_ID: "abc",
          ),
        ]
      end

      it "adds an order id missing error" do
        subject.load_records
        expect(subject.errors).to be_present
        expect(subject.errors.first.dig(:detail, :messages).first).to include("abc")
      end
    end

    context "when some order ids are in OST but not in Ultrasignup" do
      let(:proto_records) do
        [
          ProtoRecord.new(
            Order_ID: "123",
          ),
          ProtoRecord.new(
            Order_ID: "456",
          ),
        ]
      end

      it "adds an order id outdated error" do
        subject.load_records
        expect(subject.errors).to be_present
        expect(subject.errors.first.dig(:detail, :messages).first).to include("789")
      end
    end
  end
end
