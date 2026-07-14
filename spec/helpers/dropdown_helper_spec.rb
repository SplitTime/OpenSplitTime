require "rails_helper"

RSpec.describe DropdownHelper, type: :helper do
  describe "#person_actions_dropdown_menu" do
    subject(:menu) { Capybara.string(helper.person_actions_dropdown_menu(view_object)) }

    let(:view_object) { Struct.new(:person, :current_user).new(people(:alfreda_cruickshank), users(:admin_user)) }

    it "wires the Delete person link for Turbo, not legacy UJS attributes" do
      link = menu.find_link("Delete person")

      expect(link["data-turbo-method"]).to eq("delete")
      expect(link["data-turbo-confirm"]).to be_present
      expect(link["data-method"]).to be_nil
      expect(link["data-confirm"]).to be_nil
    end
  end

  describe "#roster_actions_dropdown" do
    subject(:menu) { Capybara.string(helper.roster_actions_dropdown(view_object)) }

    let(:view_object) { Struct.new(:event_group).new(event_groups(:sum)) }

    it "wires the Set data status link for Turbo, not legacy UJS attributes" do
      link = menu.find_link("Set data status")

      expect(link["data-turbo-method"]).to eq("patch")
      expect(link["data-method"]).to be_nil
    end
  end
end
