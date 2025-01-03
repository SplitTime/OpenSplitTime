module CoreExt
  module ActionView
    module Helpers
      module UrlHelper
        # Monkey Patch link_to to translate the boolean attribute "disabled" into a class
        # Using the signature (*args, &blocks) makes this patch resistant to API changes
        # since all args are captured as is
        def link_to(*args, &block)
          # Locate first hash in args with :disabled, and modify in place
          options = args.find do |hash|
            hash.key?(:disabled)
          rescue StandardError
            false
          end
          options[:class] = [options[:class], "disabled"].join(" ") if options && options[:disabled]
          original_link_to(*args, &block) # Call original link_to
        end
      end
    end
  end
end

module ActionView
  module Helpers
    module UrlHelper
      include CoreExt::ActionView::Helpers::UrlHelper

      alias original_link_to link_to
    end
  end
end
