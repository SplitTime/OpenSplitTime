# Inspired by and largely copied from the font_awesome5_rails gem
module FontAwesome6
  module Rails
    module IconHelper
      def fa6_icon(icon_name, options = {})
        FontAwesome6::Parsers::IconParser.new(icon_name, options).render
      end
      alias_method :fa_icon, :fa6_icon
    end
  end
end
