# frozen_string_literal: true

require_relative '../../lib/time_difference'

RSpec.describe TimeDifference do
  before(:context) do
    ENV['TZ'] = 'UTC'
  end

  after(:context) do
    ENV['TZ'] = nil
  end

  def self.with_each_class(&block)
    classes = [Time, Date, DateTime]

    classes.each do |clazz|
      context "with a #{clazz.name} class" do
        instance_exec clazz, &block
      end
    end
  end

  describe '.between' do
    with_each_class do |clazz|
      it 'returns a new TimeDifference instance in each component' do
        start_time = clazz.new(2011, 1)
        end_time = clazz.new(2011, 12)

        expect(TimeDifference.between(start_time, end_time)).to be_a(TimeDifference)
      end
    end
  end

  describe '.from' do
    with_each_class do |clazz|
      it 'returns a new TimeDifference instance in each component' do
        start_time = clazz.new(2011, 1)
        end_time = clazz.new(2011, 12)

        expect(TimeDifference.from(start_time, end_time)).to be_a(TimeDifference)
      end
    end
  end

  context 'when instantiating via .between' do
    describe '#in_years' do
      with_each_class do |clazz|
        it 'returns time difference in years based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.between(start_time, end_time).in_years).to eql(0.91)
        end

        it 'returns an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.between(start_time, end_time).in_years).to eql(0.91)
        end
      end
    end

    describe '#in_months' do
      with_each_class do |clazz|
        it 'returns time difference in months based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.between(start_time, end_time).in_months).to eql(10.98)
        end

        it 'returns an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.between(start_time, end_time).in_months).to eql(10.98)
        end
      end
    end

    describe '#in_weeks' do
      with_each_class do |clazz|
        it 'returns time difference in weeks based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.between(start_time, end_time).in_weeks).to eql(47.71)
        end

        it 'returns an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.between(start_time, end_time).in_weeks).to eql(47.71)
        end
      end
    end

    describe '#in_days' do
      with_each_class do |clazz|
        it 'returns time difference in weeks based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.between(start_time, end_time).in_days).to eql(334.0)
        end

        it 'returns an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.between(start_time, end_time).in_days).to eql(334.0)
        end
      end
    end

    describe '#in_hours' do
      with_each_class do |clazz|
        it 'returns time difference in hours based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.between(start_time, end_time).in_hours).to eql(8016.0)
        end

        it 'returns an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.between(start_time, end_time).in_hours).to eql(8016.0)
        end
      end
    end

    describe '#in_minutes' do
      with_each_class do |clazz|
        it 'returns time difference in minutes based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.between(start_time, end_time).in_minutes).to eql(480960.0)
        end

        it 'returns an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.between(start_time, end_time).in_minutes).to eql(480960.0)
        end
      end
    end

    describe '#in_seconds' do
      with_each_class do |clazz|
        it 'returns time difference in seconds based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.between(start_time, end_time).in_seconds).to eql(28857600.0)
        end

        it 'returns an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.between(start_time, end_time).in_seconds).to eql(28857600.0)
        end
      end
    end

    describe '#in_milliseconds' do
      with_each_class do |clazz|
        it 'returns time difference in milliseconds based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.between(start_time, end_time).in_milliseconds).to eql(28857600000)
        end

        it 'returns an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.between(start_time, end_time).in_milliseconds).to eql(28857600000)
        end
      end
    end
  end
  
  # Added method .from to allow calculation without converting to absolute values
  
  context 'when instantiating via .from' do
    describe '#in_years' do
      with_each_class do |clazz|
        it 'returns time difference in years based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.from(start_time, end_time).in_years).to eql(0.91)
        end

        it 'does not return an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.from(start_time, end_time).in_years).to eql(-0.91)
        end
      end
    end

    describe '#in_months' do
      with_each_class do |clazz|
        it 'returns time difference in months based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.from(start_time, end_time).in_months).to eql(10.98)
        end

        it 'does not return an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.from(start_time, end_time).in_months).to eql(-10.98)
        end
      end
    end

    describe '#in_weeks' do
      with_each_class do |clazz|
        it 'returns time difference in weeks based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.from(start_time, end_time).in_weeks).to eql(47.71)
        end

        it 'does not return an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.from(start_time, end_time).in_weeks).to eql(-47.71)
        end
      end
    end

    describe '#in_days' do
      with_each_class do |clazz|
        it 'returns time difference in weeks based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.from(start_time, end_time).in_days).to eql(334.0)
        end

        it 'does not return an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.from(start_time, end_time).in_days).to eql(-334.0)
        end
      end
    end

    describe '#in_hours' do
      with_each_class do |clazz|
        it 'returns time difference in hours based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.from(start_time, end_time).in_hours).to eql(8016.0)
        end

        it 'does not return an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.from(start_time, end_time).in_hours).to eql(-8016.0)
        end
      end
    end

    describe '#in_minutes' do
      with_each_class do |clazz|
        it 'returns time difference in minutes based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.from(start_time, end_time).in_minutes).to eql(480960.0)
        end

        it 'does not return an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.from(start_time, end_time).in_minutes).to eql(-480960.0)
        end
      end
    end

    describe '#in_seconds' do
      with_each_class do |clazz|
        it 'returns time difference in seconds based on Wolfram Alpha' do
          start_time = clazz.new(2011, 1)
          end_time = clazz.new(2011, 12)

          expect(TimeDifference.from(start_time, end_time).in_seconds).to eql(28857600.0)
        end

        it 'does not return an absolute difference' do
          start_time = clazz.new(2011, 12)
          end_time = clazz.new(2011, 1)

          expect(TimeDifference.from(start_time, end_time).in_seconds).to eql(-28857600.0)
        end
      end
    end
  end
end
