require "rails_helper"
require "fugit"

RSpec.describe "config/recurring.yml" do
  let(:config) { YAML.safe_load(ERB.new(File.read(Rails.root.join("config/recurring.yml"))).result, permitted_classes: [Symbol]) }

  it "contains only valid recurring schedules" do
    config.each do |_env, tasks|
      next unless tasks.is_a?(Hash)

      tasks.each do |name, task|
        parsed = Fugit.parse(task["schedule"])
        expect(parsed).to be_a(Fugit::Cron), "#{name}: '#{task["schedule"]}' is not a valid recurring schedule"
      end
    end
  end
end
