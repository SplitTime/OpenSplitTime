require 'rails_helper'
require 'pry-byebug'

RSpec.describe EffortRow, type: :model do

  before do

    @course = Course.create!(name: 'Test Course 100')
    @event1 = Event.create!(name: 'Test Event 2012', course: @course, start_time: "2012-07-01 06:00:00", laps_required: 1)
    @event2 = Event.create!(name: 'Test Event 2013', course: @course, start_time: "2013-07-01 06:00:00", laps_required: 1)
    @event3 = Event.create!(name: 'Test Event 2014', course: @course, start_time: "2014-07-01 06:00:00", laps_required: 1)
    @event4 = Event.create!(name: 'Test Event 2015', course: @course, start_time: "2015-07-01 06:00:00", laps_required: 1)

    @effort1 = Effort.create!(event: @event1, bib_number: 1, state_code: 'BC', country_code: 'CA', age: 50, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
    @effort2 = Effort.create!(event: @event1, bib_number: 2, state_code: 'CO', country_code: 'US', age: 23, first_name: 'Joe', last_name: 'Hardman', gender: 'male')
    @effort3 = Effort.create!(event: @event2, bib_number: 3, state_code: 'CO', country_code: 'US', age: 24, first_name: 'Mark', last_name: 'Runner', gender: 'male')
    @effort4 = Effort.create!(event: @event2, bib_number: 4, state_code: 'CO', country_code: 'US', age: 25, first_name: 'Pete', last_name: 'Trotter', gender: 'male')
    @effort5 = Effort.create!(event: @event3, bib_number: 5, state_code: 'CO', country_code: 'US', age: 26, first_name: 'James', last_name: 'Walker', gender: 'male')
    @effort6 = Effort.create!(event: @event3, bib_number: 6, state_code: 'CO', country_code: 'US', age: 27, first_name: 'Johnny', last_name: 'Hiker', gender: 'male')
    @effort7 = Effort.create!(event: @event4, bib_number: 7, state_code: 'CO', country_code: 'US', age: 28, first_name: 'Melissa', last_name: 'Getter', gender: 'female')
    @effort8 = Effort.create!(event: @event4, bib_number: 8, state_code: 'CO', country_code: 'US', age: 29, first_name: 'George', last_name: 'Ringer', gender: 'male')

  end

  describe 'initialization' do
    it 'should instantiate new objects if provided an effort' do
      @effort_row1 = EffortRow.new(@effort1)
      @effort_row2 = EffortRow.new(@effort2)
      @effort_row3 = EffortRow.new(@effort3)
      @effort_row4 = EffortRow.new(@effort4)

      expect(@effort_row1.present?).to eq(true)
      expect(@effort_row2.present?).to eq(true)
      expect(@effort_row3.present?).to eq(true)
      expect(@effort_row4.present?).to eq(true)
    end

    it 'should instantiate an EffortRow if an effort and other options are provided' do
      @effort_row5 = EffortRow.new(effort: @effort5, overall_rank: 10, gender_rank: 5, start_time: "1992-07-01 06:00:00")
      @effort_row6 = EffortRow.new(effort: @effort6, overall_rank: 10, finish_status: 50000, start_time: "2015-07-01 06:00:00")
      @effort_row7 = EffortRow.new(effort: @effort7, finish_status: "DNF at Ridgeline")
      @effort_row8 = EffortRow.new(effort: @effort8, gender_rank: 3)

      expect(@effort_row5.present?).to eq(true)
      expect(@effort_row6.present?).to eq(true)
      expect(@effort_row7.present?).to eq(true)
      expect(@effort_row8.present?).to eq(true)
    end
  end

  describe 'year' do
    it 'should return the year of start_time if provided' do
      @effort_row5 = EffortRow.new(effort: @effort5, overall_rank: 10, gender_rank: 5, start_time: "1992-02-01 00:00:00")
      @effort_row6 = EffortRow.new(effort: @effort6, overall_rank: 10, finish_status: 50000, start_time: "2015-07-01 06:00:00")

      expect(@effort_row5.year).to eq(1992)
      expect(@effort_row6.year).to eq(2015)
    end

    it 'should return the year of the effort.event_start_time if available' do
      @effort_row2 = EffortRow.new(effort: @effort2, overall_rank: 10, gender_rank: 5)
      @effort_row5 = EffortRow.new(effort: @effort5, overall_rank: 10, finish_status: 50000)

      expect(@effort_row2.year).to eq(2012)
      expect(@effort_row5.year).to eq(2014)
    end
  end

  describe 'finish_time' do
    it 'should return nil if no finish_status is provided or if finish_status is a string' do
      @effort_row7 = EffortRow.new(effort: @effort7, finish_status: "DNF at Ridgeline")
      @effort_row8 = EffortRow.new(effort: @effort8, gender_rank: 3)

      expect(@effort_row7.finish_time).to be_nil
      expect(@effort_row8.finish_time).to be_nil
    end

    it 'should return finish_status if finish_status is numeric' do
      @effort_row4 = EffortRow.new(effort: @effort4, finish_status: 25000)
      @effort_row6 = EffortRow.new(effort: @effort6, overall_rank: 10, finish_status: 50000, start_time: "2015-07-01 06:00:00")

      expect(@effort_row4.finish_time).to eq(25000)
      expect(@effort_row6.finish_time).to eq(50000)
    end
  end

  describe 'effort_attributes' do
    it 'should return delegated effort attributes' do
      @effort_row1 = EffortRow.new(effort: @effort1)
      @effort_row2 = EffortRow.new(effort: @effort2)
      @effort_row3 = EffortRow.new(effort: @effort3)
      @effort_row4 = EffortRow.new(effort: @effort4)

      expect(@effort_row1.first_name).to eq('Jen')
      expect(@effort_row2.last_name).to eq('Hardman')
      expect(@effort_row3.gender).to eq('male')
      expect(@effort_row4.state_code).to eq('CO')
      expect(@effort_row1.age).to eq(50)
    end

    it 'should properly return attributes from PersonalInfo module' do
      @effort_row5 = EffortRow.new(effort: @effort5)
      @effort_row6 = EffortRow.new(effort: @effort6)
      @effort_row7 = EffortRow.new(effort: @effort7)
      @effort_row8 = EffortRow.new(effort: @effort8)

      expect(@effort_row5.full_name).to eq('James Walker')
      expect(@effort_row6.bio_historic).to eq('Male, 27')
      expect(@effort_row7.state_and_country).to eq('Colorado, US')
    end
  end
end