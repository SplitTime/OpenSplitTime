# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Exporter::ExportService do
  subject { described_class.new(resource_class, resources, export_attributes) }
  let(:resource_class) { ::Organization }
  let(:resources) { ::Organization.all.order(:name) }
  let(:export_attributes) { [:name, :slug, :concealed] }

  describe "#csv_to_file" do
    let(:file_path) { Pathname.new(File.join(file_fixture_path, "temp.csv")) }
    let!(:file) { File.open(file_path, "w") }
    let(:resulting_lines) { File.readlines(file) }
    let(:expected_header) { "Name,Slug,Concealed" }

    after { File.delete(file) }

    context "when provided with a small number of resources" do
      it "exports resource headers to the file" do
        subject.csv_to_file(file)
        file.close

        expect(resulting_lines.first.chomp).to eq(expected_header)
      end

      it "exports each resource preserving sort order" do
        subject.csv_to_file(file)
        file.close

        expect(resulting_lines.count).to eq(5)
        expect(resulting_lines.second.chomp).to eq("Dirty 30 Running,dirty-30-running,false")
        expect(resulting_lines.last.chomp).to eq("Running Up For Air,running-up-for-air,false")
      end
    end

    context "when one or more commas exist within resource attributes" do
      before { organizations(:dirty_30_running).update(name: "Dirty 30, Running") }

      it "exports resource headers to the file" do
        subject.csv_to_file(file)
        file.close

        expect(resulting_lines.first.chomp).to eq(expected_header)
      end

      it "adds escaped quotation marks where needed" do
        subject.csv_to_file(file)
        file.close

        expect(resulting_lines.count).to eq(5)
        expect(resulting_lines.second.chomp).to eq("\"Dirty 30, Running\",dirty-30-running,false")
        expect(resulting_lines.last.chomp).to eq("Running Up For Air,running-up-for-air,false")
      end
    end

    context "when one or non-ascii characters exist within resource attributes" do
      before { organizations(:dirty_30_running).update(name: "Dirty 30 Ruñning") }

      it "exports resource headers to the file" do
        subject.csv_to_file(file)
        file.close

        expect(resulting_lines.first.chomp).to eq(expected_header)
      end

      it "adds escaped quotation marks where needed" do
        subject.csv_to_file(file)
        file.close

        expect(resulting_lines.count).to eq(5)
        expect(resulting_lines.second.chomp).to eq("Dirty 30 Ruñning,dirty-30-running,false")
        expect(resulting_lines.last.chomp).to eq("Running Up For Air,running-up-for-air,false")
      end
    end

    context "when provided with a number of resources that is greater than the batch size" do
      let(:resource_class) { ::Effort }
      let(:resources) { ::Effort.order(:last_name) }
      let(:export_attributes) { [:id, :first_name, :last_name, :state_code] }
      let(:expected_header) { "Id,First name,Last name,State code" }
      let(:stubbed_batch_size) { 25 }

      before { stub_const("#{described_class}::BATCH_SIZE", stubbed_batch_size) }

      it "exports resource headers to the file" do
        subject.csv_to_file(file)
        file.close

        expect(resulting_lines.first.chomp).to eq(expected_header)
      end

      it "exports each resource preserving the given sort order" do
        subject.csv_to_file(file)
        file.close

        expect(::Effort.count).to be > stubbed_batch_size
        expect(resulting_lines.count).to eq(::Effort.count + 1)
        expect(resulting_lines.second.chomp).to eq("121,Susanna,Abshire,CO")
        expect(resulting_lines.last.chomp).to eq("4246,Omer,Yundt,CO")
      end
    end
  end
end
