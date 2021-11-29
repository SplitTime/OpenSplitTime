# frozen_string_literal: true

require_relative '../../app/services/args_validator'

RSpec.describe ArgsValidator do
  describe '#initialize' do
    it 'creates a new object using an empty args hash' do
      args = {}
      expect { ArgsValidator.new(params: args) }.not_to raise_error
    end

    it 'creates a new object using a populated args hash with no requirements given' do
      args = {bib_number: 123, effort_id: 456}
      expect { ArgsValidator.new(params: args) }.not_to raise_error
    end

    it 'raises ArgumentError if no params argument is given' do
      args = nil
      expect { ArgsValidator.new(params: args) }.to raise_error(/no arguments provided/)
    end

    it 'raises ArgumentError if any unknown argument is given' do
      args = {bib_number: 123, effort_id: 456}
      expect { ArgsValidator.new(params: args, super_secret_required: :effort_id) }.to raise_error(/may not include super_secret_required/)
    end

    it 'instantiates an object when provided a fully populated set of parameters' do
      args = {bib_number: 123, effort_id: 456}
      required = [:bib_number, :effort_id, :other_param]
      required_alternatives = [:pick_one, :pick_the_other]
      klass = Effort
      expect { ArgsValidator.new(params: args, required: required, required_alternatives: required_alternatives, class: klass) }
          .not_to raise_error
    end

    it 'instantiates an object when provided a subject and subject_class' do
      args = {subject: Effort.new, subject_class: Effort}
      expect { ArgsValidator.new(params: args) }.not_to raise_error
    end
  end

  describe '#validate and .validate' do
    it 'reports any deprecated args as determined by the calling class' do
      args = {bib: 123, effort_id: 456, other_param: 789}
      deprecated = {bib: :bib_number}
      expect { ArgsValidator.new(params: args, deprecated: deprecated).validate }
          .to output(/use of 'bib' has been deprecated in favor of 'bib_number'/).to_stderr
      expect { ArgsValidator.validate(params: args, deprecated: deprecated) }
          .to output(/use of 'bib' has been deprecated in favor of 'bib_number'/).to_stderr
    end

    it 'reports only those deprecated args that are used in params' do
      args = {c: 123, d: 456}
      deprecated = {a: :b, c: :d}
      expect { ArgsValidator.new(params: args, deprecated: deprecated).validate }
          .to_not output(/use of 'a' has been deprecated in favor of 'b'/).to_stderr
      expect { ArgsValidator.new(params: args, deprecated: deprecated).validate }
          .to output(/use of 'c' has been deprecated in favor of 'd'/).to_stderr
      expect { ArgsValidator.validate(params: args, deprecated: deprecated) }
          .to_not output(/use of 'a' has been deprecated in favor of 'b'/).to_stderr
      expect { ArgsValidator.validate(params: args, deprecated: deprecated) }
          .to output(/use of 'c' has been deprecated in favor of 'd'/).to_stderr
    end

    it 'raises ArgumentError if subject key is given but subject is not provided' do
      expect { ArgsValidator.new(subject: nil, params: {}).validate }
          .to raise_error(/arguments must include a subject/)
    end

    it 'raises ArgumentError if subject_class is given but subject is not an instance of subject_class' do
      expect { ArgsValidator.new(subject: Effort.new, subject_class: SplitTime, params: {}).validate }
          .to raise_error(/subject must be a SplitTime/)
    end

    it 'raises ArgumentError if params argument is not a Hash' do
      args = 123
      expect { ArgsValidator.new(params: args).validate }.to raise_error(/must be provided as a hash/)
      expect { ArgsValidator.validate(params: args) }.to raise_error(/must be provided as a hash/)
    end

    it 'validates an empty args hash' do
      args = {}
      expect { ArgsValidator.new(params: args).validate }.not_to raise_error
      expect { ArgsValidator.validate(params: args) }.not_to raise_error
    end

    it 'validates a populated args hash when no params are required' do
      args = {bib_number: 123, effort_id: 456}
      expect { ArgsValidator.new(params: args).validate }.not_to raise_error
      expect { ArgsValidator.validate(params: args) }.not_to raise_error
    end

    it 'validates a populated args hash that includes a single required param' do
      args = {bib_number: 123, effort_id: 456, other_param: 789}
      required = :bib_number
      expect { ArgsValidator.new(params: args, required: required).validate }.not_to raise_error
      expect { ArgsValidator.validate(params: args, required: required) }.not_to raise_error
    end

    it 'validates a populated args hash that includes all of multiple required params' do
      args = {bib_number: 123, effort_id: 456, other_param: 789}
      required = [:bib_number, :effort_id]
      expect { ArgsValidator.new(params: args, required: required).validate }.not_to raise_error
      expect { ArgsValidator.validate(params: args, required: required) }.not_to raise_error
    end

    it 'validates a populated args hash that includes a single required_alternative param' do
      args = {bib_number: 123, effort_id: 456, other_param: 789}
      required_alternatives = :other_param
      expect { ArgsValidator.new(params: args, required_alternatives: required_alternatives).validate }.not_to raise_error
      expect { ArgsValidator.validate(params: args, required_alternatives: required_alternatives) }.not_to raise_error
    end

    it 'validates a populated args hash that includes one of multiple required_alternative params' do
      args = {bib_number: 123, effort_id: 456, other_param: 789}
      required_alternatives = [:other_param, :yet_another_param]
      expect { ArgsValidator.new(params: args, required_alternatives: required_alternatives).validate }.not_to raise_error
      expect { ArgsValidator.validate(params: args, required_alternatives: required_alternatives) }.not_to raise_error
    end

    it 'validates a populated args hash that includes one required_alternative params when the alternative is a set of multiple params' do
      args = {param_a: 456}
      required_alternatives = [:param_a, [:param_b1, :param_b2]]
      expect { ArgsValidator.new(params: args, required_alternatives: required_alternatives).validate }.not_to raise_error
      expect { ArgsValidator.validate(params: args, required_alternatives: required_alternatives) }.not_to raise_error
    end

    it 'validates a populated args hash that includes one of a set of multiple required_alternative params' do
      args = {param_b1: 123, param_b2: 456}
      required_alternatives = [:param_a, [:param_b1, :param_b2]]
      expect { ArgsValidator.new(params: args, required_alternatives: required_alternatives).validate }.not_to raise_error
      expect { ArgsValidator.validate(params: args, required_alternatives: required_alternatives) }.not_to raise_error
    end

    it 'invalidates a populated args hash that includes only a portion of a set of multiple required_alternative params' do
      args = {param_b1: 123}
      required_alternatives = [:param_a, [:param_b1, :param_b2]]
      expect { ArgsValidator.new(params: args, required_alternatives: required_alternatives).validate }
          .to raise_error(/must include one of param_a or param_b1 and param_b2/)
      expect { ArgsValidator.validate(params: args, required_alternatives: required_alternatives) }
          .to raise_error(/must include one of param_a or param_b1 and param_b2/)
    end

    it 'validates a populated args hash that includes all required params and at least one required_alternative param' do
      args = {bib_number: 123, effort_id: 456, other_param: 789}
      required = [:bib_number, :effort_id]
      required_alternatives = [:other_param, :yet_another_param]
      expect { ArgsValidator.new(params: args, required: required, required_alternatives: required_alternatives).validate }
          .not_to raise_error
      expect { ArgsValidator.validate(params: args, required: required, required_alternatives: required_alternatives) }
          .not_to raise_error
    end

    it 'invalidates a populated args hash that does not include all required params' do
      args = {bib_number: 123, other_param: 789}
      required = [:bib_number, :effort_id]
      expect { ArgsValidator.new(params: args, required: required).validate }
          .to raise_error(/must include effort_id/)
      expect { ArgsValidator.validate(params: args, required: required) }
          .to raise_error(/must include effort_id/)
    end

    it 'properly recognizes false as being present for purposes of required params' do
      args = {bib_number: 123, finished: false}
      required = [:bib_number, :finished]
      expect { ArgsValidator.new(params: args, required: required).validate }
          .not_to raise_error
      expect { ArgsValidator.validate(params: args, required: required) }
          .not_to raise_error
    end

    it 'invalidates a populated args hash that does not include any required_alternative param' do
      args = {bib_number: 123, effort_id: 456}
      required_alternatives = [:other_param, :yet_another_param]
      expect { ArgsValidator.new(params: args, required_alternatives: required_alternatives).validate }
          .to raise_error(/must include one of/)
      expect { ArgsValidator.validate(params: args, required_alternatives: required_alternatives) }
          .to raise_error(/must include one of/)
    end

    it 'invalidates a populated args hash that if the only required_alternative param is nil' do
      args = {bib_number: 123, other_param: nil}
      required_alternatives = [:other_param, :yet_another_param]
      expect { ArgsValidator.new(params: args, required_alternatives: required_alternatives).validate }
          .to raise_error(/must include one of/)
      expect { ArgsValidator.validate(params: args, required_alternatives: required_alternatives) }
          .to raise_error(/must include one of/)
    end

    it 'properly recognizes false as being present for purposes of required alternatives' do
      args = {bib_number: 123, finished: false}
      required_alternatives = [:finished, :other_param]
      expect { ArgsValidator.new(params: args, required_alternatives: required_alternatives).validate }
          .not_to raise_error
      expect { ArgsValidator.validate(params: args, required_alternatives: required_alternatives) }
          .not_to raise_error
    end

    it 'validates a populated args hash if the single given param is the same as the single exclusive param' do
      args = {bib_number: 123}
      exclusive = :bib_number
      expect { ArgsValidator.new(params: args, exclusive: exclusive).validate }.not_to raise_error
      expect { ArgsValidator.validate(params: args, exclusive: exclusive) }.not_to raise_error
    end

    it 'validates a populated args hash if all params are included in the exclusive param set' do
      args = {bib_number: 123, effort_id: 456}
      exclusive = [:bib_number, :effort_id, :other_param]
      expect { ArgsValidator.new(params: args, exclusive: exclusive).validate }.not_to raise_error
      expect { ArgsValidator.validate(params: args, exclusive: exclusive) }.not_to raise_error
    end

    it 'invalidates a populated args hash if any param is not included in the exclusive param set' do
      args = {bib_number: 123, effort_id: 456, other_param: 789}
      exclusive = [:bib_number, :effort_id]
      expect { ArgsValidator.new(params: args, exclusive: exclusive).validate }
          .to raise_error(/may not include other_param/)
      expect { ArgsValidator.validate(params: args, exclusive: exclusive) }
          .to raise_error(/may not include other_param/)
    end
  end
end
