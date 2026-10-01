require "rails_helper"

# Madmin builds permitted params from every form-visible attribute a resource declares and
# passes them straight to update/create. An attribute that no longer exists on the model
# raises ActiveModel::UnknownAttributeError on every save, so catch the drift here.
RSpec.describe Madmin::Resource do
  resources_root = Rails.root.join("app/madmin/resources")
  resource_classes = Rails.root.glob("app/madmin/resources/**/*_resource.rb").map do |path|
    path.relative_path_from(resources_root).to_s.delete_suffix(".rb").camelize.constantize
  end

  resource_classes.each do |resource_class|
    describe resource_class do
      it "declares only form attributes that the model can assign" do
        model = described_class.model
        form_attributes = described_class.attributes.values.select { |attribute| attribute.field.visible?(:edit) }

        unassignable = form_attributes.reject do |attribute|
          name = attribute.name.to_s
          model.attribute_names.include?(name) ||
            model.reflect_on_association(attribute.name).present? ||
            model.method_defined?(:"#{name}=")
        end

        expect(unassignable.map(&:name)).to be_empty
      end
    end
  end
end
