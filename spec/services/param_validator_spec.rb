require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe ParamValidator do
  describe '#initialize' do
    it 'creates a new object using an empty args hash' do
      args = {}
      expect { ParamValidator.new(params: args) }.not_to raise_error
    end

    it 'creates a new object using a populated args hash with no requirements given' do
      args = {time_from_start: 123, effort_id: 456}
      expect { ParamValidator.new(params: args) }.not_to raise_error
    end

    it 'raises ArgumentError if no params argument is given' do
      args = nil
      expect { ParamValidator.new(params: args) }.to raise_error(/no parameters provided/)
    end

    it 'instantiates an object when provided a fully populated set of parameters' do
      args = {time_from_start: 123, effort_id: 456}
      required = [:time_from_start, :effort_id, :other_param]
      required_alternatives = [:pick_one, :pick_the_other]
      klass = Effort
      expect { ParamValidator.new(params: args, required: required, required_alternatives: required_alternatives, klass: klass) }
          .not_to raise_error
    end
  end

  describe '#validate and .validate' do
    it 'raises ArgumentError if params argument is not a Hash' do
      args = 123
      expect { ParamValidator.new(params: args).validate }.to raise_error(/must be provided as a hash/)
      expect { ParamValidator.validate(params: args) }.to raise_error(/must be provided as a hash/)
    end

    it 'validates an empty args hash' do
      args = {}
      expect { ParamValidator.new(params: args).validate }.not_to raise_error
      expect { ParamValidator.validate(params: args) }.not_to raise_error
    end

    it 'validates a populated args hash when no params are required' do
      args = {time_from_start: 123, effort_id: 456}
      expect { ParamValidator.new(params: args).validate }.not_to raise_error
      expect { ParamValidator.validate(params: args) }.not_to raise_error
    end

    it 'validates a populated args hash that includes all required params' do
      args = {time_from_start: 123, effort_id: 456, other_param: 789}
      required = [:time_from_start, :effort_id]
      expect { ParamValidator.new(params: args, required: required).validate }.not_to raise_error
      expect { ParamValidator.validate(params: args, required: required) }.not_to raise_error
    end

    it 'validates a populated args hash that includes one required_alternative param' do
      args = {time_from_start: 123, effort_id: 456, other_param: 789}
      required_alternatives = [:other_param, :yet_another_param]
      expect { ParamValidator.new(params: args, required_alternatives: required_alternatives).validate }.not_to raise_error
      expect { ParamValidator.validate(params: args, required_alternatives: required_alternatives) }.not_to raise_error
    end

    it 'validates a populated args hash that includes all required params and at least one required_alternative param' do
      args = {time_from_start: 123, effort_id: 456, other_param: 789}
      required = [:time_from_start, :effort_id]
      required_alternatives = [:other_param, :yet_another_param]
      expect { ParamValidator.new(params: args, required: required, required_alternatives: required_alternatives).validate }
          .not_to raise_error
      expect { ParamValidator.validate(params: args, required: required, required_alternatives: required_alternatives) }
          .not_to raise_error
    end

    it 'invalidates a populated args hash that does not include all required params' do
      args = {time_from_start: 123, other_param: 789}
      required = [:time_from_start, :effort_id]
      expect { ParamValidator.new(params: args, required: required).validate }
          .to raise_error(/must include all of/)
      expect { ParamValidator.validate(params: args, required: required) }
          .to raise_error(/must include all of/)
    end

    it 'invalidates a populated args hash that does not include any required_alternative param' do
      args = {time_from_start: 123, effort_id: 456}
      required_alternatives = [:other_param, :yet_another_param]
      expect { ParamValidator.new(params: args, required_alternatives: required_alternatives).validate }
          .to raise_error(/must include one of/)
      expect { ParamValidator.validate(params: args, required_alternatives: required_alternatives) }
          .to raise_error(/must include one of/)
    end

    it 'validates a populated args hash if all params are included in the exclusive param set' do
      args = {time_from_start: 123, effort_id: 456}
      exclusive = [:time_from_start, :effort_id, :other_param]
      expect { ParamValidator.new(params: args, exclusive: exclusive).validate }.not_to raise_error
      expect { ParamValidator.validate(params: args, exclusive: exclusive) }.not_to raise_error
    end

    it 'invalidates a populated args hash if any param is not included in the exclusive param set' do
      args = {time_from_start: 123, effort_id: 456, other_param: 789}
      exclusive = [:time_from_start, :effort_id]
      expect { ParamValidator.new(params: args, exclusive: exclusive).validate }
          .to raise_error(/may include only/)
      expect { ParamValidator.validate(params: args, exclusive: exclusive) }
          .to raise_error(/may include only/)
    end
  end
end