RSpec.shared_examples_for "auditable" do
  let(:model) { described_class }
  let(:model_name) { model.name.underscore.to_sym }

  describe "before validation" do
    let(:current_user) { build_stubbed(:user, id: 1) }
    let(:existing_user) { build_stubbed(:user, id: 2) }

    it "adds the current user id to created_by" do
      allow(User).to receive(:current).and_return(current_user)
      resource = build_stubbed(model_name, created_by: nil)
      resource.validate
      expect(resource.created_by).to eq(current_user.id)
    end

    it "does not change created_by if it already exists" do
      allow(User).to receive(:current).and_return(current_user)
      resource = build_stubbed(model_name, created_by: existing_user.id)
      resource.validate
      expect(resource.created_by).to eq(existing_user.id)
    end

    it "does not change created_by if User.current is not available" do
      allow(User).to receive(:current).and_return(nil)
      resource = build_stubbed(model_name, created_by: nil)
      resource.validate
      expect(resource.created_by).to eq(nil)
    end
  end
end
