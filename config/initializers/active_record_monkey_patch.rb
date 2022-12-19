# frozen_string_literal: true

# Credit to Harish Shetty
# https://stackoverflow.com/a/2315469/5961578
class ActiveRecord::Base
  def self.all_polymorphic_types(name)
    @poly_hash ||= {}.tap do |hash|
      Dir.glob(File.join(Rails.root, "app", "models", "**", "*.rb")).each do |file|
        file.sub!(File.join(Rails.root, "app", "models"), "")
        file.sub!(".rb", "")
        klass = file.classify.safe_constantize

        next if klass.nil?
        next unless klass.ancestors.include?(ActiveRecord::Base)

        klass.reflect_on_all_associations(:has_many).select { |r| r.options[:as] }.each do |reflection|
          (hash[reflection.options[:as]] ||= []) << klass
        end
      end
    end
    @poly_hash[name.to_sym]
  end
end
