
module ActionView
  module Helpers
    module UrlHelper

      alias_method :original_link_to, :link_to
      # Monkey Patch link_to to translate the boolean attribute "disabled" into a class
      # Using the signature (*args, &blocks) makes this patch resistant to API changes
      # since all args are captured as is
      def link_to(*args, &block)
        # Locate first hash in args with :disabled, and modify in place
        options = args.find { |hash| hash.key?(:disabled) rescue false }
        if options and options[:disabled]
          options[:class] = [options[:class], 'disabled'].join(' ')
        end
        original_link_to(*args, &block) # Call original link_to
      end
    end
  end
end