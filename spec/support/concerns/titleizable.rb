# frozen_string_literal: true

RSpec.shared_examples_for "titleizable" do |*titleizable_attribute_names|
  subject { described_class.new }

  describe ".titleizable_attribute_names" do
    it "sets as expected" do
      expected_attribute_names = titleizable_attribute_names.map(&:to_s)
      expect(described_class.titleizable_attribute_names).to match_array(expected_attribute_names)
    end
  end

  describe "before validation" do
    titleizable_attribute_names.each do |attribute_name|
      context "for attribute #{attribute_name}" do
        let(:setter_method) { "#{attribute_name}=" }
        it "titleizes all-lowercased fields" do
          subject.send(setter_method, "lazy name")
          subject.validate

          expect(subject.send(attribute_name)).to eq("Lazy Name")
        end

        it "titleizes all-uppercased fields" do
          subject.send(setter_method, "SHOUTING NAME")
          subject.validate

          expect(subject.send(attribute_name)).to eq("Shouting Name")
        end
      end
    end
  end
end
