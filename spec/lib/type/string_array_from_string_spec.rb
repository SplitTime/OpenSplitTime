# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Type::StringArrayFromString do
  module TestDummy
    class QueryModel
      include ::ActiveModel::Model
      include ::ActiveModel::Attributes

      attribute :names, :string_array_from_string
    end
  end

  describe "#cast" do
    subject { ::TestDummy::QueryModel.new(names: names) }
    context "when given a Postgres-style array" do
      let(:names) { "{hello,there,world}" }
      it "casts names as an array" do
        expect(subject.names).to eq(["hello", "there", "world"])
      end
    end

    context "when given a Postgres-style array with numbers and symbols" do
      let(:names) { "{hello1,there2*,world{3!}}" }
      it "casts names as an array" do
        expect(subject.names).to eq(["hello1", "there2*", "world{3!}"])
      end
    end

    context "when given an empty Postgres-style array" do
      let(:names) { "{}" }
      it "casts as an empty array" do
        expect(subject.names).to eq([])
      end
    end

    context "when given an empty string" do
      let(:names) { "" }
      it "casts as an empty array" do
        expect(subject.names).to eq([])
      end
    end

    context "when given an array" do
      let(:names) { ["hello", "there", "world"] }
      it "returns the array" do
        expect(subject.names).to eq(["hello", "there", "world"])
      end
    end

    context "when given nil" do
      let(:names) { nil }
      it "casts as an empty array" do
        expect(subject.names).to eq([])
      end
    end
  end
end
