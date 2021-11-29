# frozen_string_literal: true

# Monkey patch to get StripAttributes working with Titleizable module
module StripAttributes
  module Matchers
    class StripAttributeMatcher
      def matches?(subject)
        @attributes.all? do |attribute|
          @attribute = attribute
          subject.send("#{@attribute}=", " string ")
          subject.valid?
          subject.send(@attribute).downcase == "string" and collapse_spaces?(subject)
        end
      end

      private

      def collapse_spaces?(subject)
        return true if !@options[:collapse_spaces]

        subject.send("#{@attribute}=", " string    string ")
        subject.valid?
        subject.send(@attribute).downcase == "string string"
      end
    end
  end
end
