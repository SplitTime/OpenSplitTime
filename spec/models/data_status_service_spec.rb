require 'rails_helper'

RSpec.describe DataStatusService do

  describe 'set_data_status' do
    before do

      @course = Course.create!(name: 'Test Course 100')
      @event = Event.create!(name: 'Test Event 2015', course: @course, start_time: "2015-07-01 06:00:00")

      @effort1 = Effort.create!(event: @event, bib_number: 1, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      @effort2 = Effort.create!(event: @event, bib_number: 2, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, first_name: 'Joe', last_name: 'Hardman', gender: 'male')
      @effort3 = Effort.create!(event: @event, bib_number: 3, city: 'Denver', state_code: 'CO', country_code: 'US', age: 24, first_name: 'Mark', last_name: 'Runner', gender: 'male')
      @effort4 = Effort.create!(event: @event, bib_number: 4, city: 'Louisville', state_code: 'CO', country_code: 'US', age: 25, first_name: 'Pete', last_name: 'Trotter', gender: 'male')
      @effort5 = Effort.create!(event: @event, bib_number: 5, city: 'Fort Collins', state_code: 'CO', country_code: 'US', age: 26, first_name: 'James', last_name: 'Walker', gender: 'male')
      @effort6 = Effort.create!(event: @event, bib_number: 6, city: 'Colorado Springs', state_code: 'CO', country_code: 'US', age: 27, first_name: 'Johnny', last_name: 'Hiker', gender: 'male')
      @effort7 = Effort.create!(event: @event, bib_number: 7, city: 'Idaho Springs', state_code: 'CO', country_code: 'US', age: 28, first_name: 'Melissa', last_name: 'Getter', gender: 'female')
      @effort8 = Effort.create!(event: @event, bib_number: 8, city: 'Grand Junction', state_code: 'CO', country_code: 'US', age: 29, first_name: 'George', last_name: 'Ringer', gender: 'male')
      @effort9 = Effort.create!(event: @event, bib_number: 9, city: 'Aspen', state_code: 'CO', country_code: 'US', age: 30, first_name: 'Abe', last_name: 'Goer', gender: 'male')
      @effort10 = Effort.create!(event: @event, bib_number: 10, city: 'Vail', state_code: 'CO', country_code: 'US', age: 31, first_name: 'Tanya', last_name: 'Doer', gender: 'female')
      @effort11 = Effort.create!(event: @event, bib_number: 11, city: 'Frisco', state_code: 'CO', country_code: 'US', age: 32, first_name: 'Sally', last_name: 'Tracker', gender: 'female')
      @effort12 = Effort.create!(event: @event, bib_number: 12, city: 'Glenwood Springs', state_code: 'CO', country_code: 'US', age: 32, first_name: 'Linus', last_name: 'Peanut', gender: 'male')
      @effort13 = Effort.create!(event: @event, bib_number: 13, city: 'Limon', state_code: 'CO', country_code: 'US', age: 32, first_name: 'Lucy', last_name: 'Peanut', gender: 'female')

      @split1 = Split.create!(course: @course, base_name: 'Starting Line', distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
      @split2 = Split.create!(course: @course, base_name: 'Aid Station 1', distance_from_start: 6000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split4 = Split.create!(course: @course, base_name: 'Aid Station 2', distance_from_start: 15000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split6 = Split.create!(course: @course, base_name: 'Finish Line', distance_from_start: 25000, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

      @event.splits << @course.splits

      SplitTime.create!(effort: @effort1, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort1, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 4000)
      SplitTime.create!(effort: @effort1, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 4100)
      SplitTime.create!(effort: @effort1, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 15200)
      SplitTime.create!(effort: @effort1, split: @split4, bitkey: SubSplit::OUT_BITKEY, time_from_start: 15100)
      SplitTime.create!(effort: @effort1, split: @split6, bitkey: SubSplit::IN_BITKEY, time_from_start: 21000)

      SplitTime.create!(effort: @effort2, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort2, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 60)
      SplitTime.create!(effort: @effort2, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 120)
      SplitTime.create!(effort: @effort2, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 24000)
      SplitTime.create!(effort: @effort2, split: @split4, bitkey: SubSplit::OUT_BITKEY, time_from_start: 150000)
      SplitTime.create!(effort: @effort2, split: @split6, bitkey: SubSplit::IN_BITKEY, time_from_start: 40000)

      SplitTime.create!(effort: @effort3, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort3, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 5000)
      SplitTime.create!(effort: @effort3, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 5000)
      SplitTime.create!(effort: @effort3, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 12200)
      SplitTime.create!(effort: @effort3, split: @split4, bitkey: SubSplit::OUT_BITKEY, time_from_start: 12300)
      SplitTime.create!(effort: @effort3, split: @split6, bitkey: SubSplit::IN_BITKEY, time_from_start: 18000)

      SplitTime.create!(effort: @effort4, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 1000)
      SplitTime.create!(effort: @effort4, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 4500)
      SplitTime.create!(effort: @effort4, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 4400)
      SplitTime.create!(effort: @effort4, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 11000)
      SplitTime.create!(effort: @effort4, split: @split4, bitkey: SubSplit::OUT_BITKEY, time_from_start: 11000)
      SplitTime.create!(effort: @effort4, split: @split6, bitkey: SubSplit::IN_BITKEY, time_from_start: 17500)

      SplitTime.create!(effort: @effort5, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort5, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 4600)
      SplitTime.create!(effort: @effort5, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 4800)
      SplitTime.create!(effort: @effort5, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 9800)
      SplitTime.create!(effort: @effort5, split: @split4, bitkey: SubSplit::OUT_BITKEY, time_from_start: 10000)
      SplitTime.create!(effort: @effort5, split: @split6, bitkey: SubSplit::IN_BITKEY, time_from_start: 14550)

      SplitTime.create!(effort: @effort6, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort6, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 9600)
      SplitTime.create!(effort: @effort6, split: @split4, bitkey: SubSplit::OUT_BITKEY, time_from_start: 9660)
      SplitTime.create!(effort: @effort6, split: @split6, bitkey: SubSplit::IN_BITKEY, time_from_start: 14650)

      SplitTime.create!(effort: @effort7, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort7, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 6300)
      SplitTime.create!(effort: @effort7, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 6600)
      SplitTime.create!(effort: @effort7, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 13000)
      SplitTime.create!(effort: @effort7, split: @split4, bitkey: SubSplit::OUT_BITKEY, time_from_start: 13500)

      SplitTime.create!(effort: @effort8, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort8, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 5500)
      SplitTime.create!(effort: @effort8, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 5500)
      SplitTime.create!(effort: @effort8, split: @split6, bitkey: SubSplit::IN_BITKEY, time_from_start: 18700)

      SplitTime.create!(effort: @effort9, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort9, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 11000)
      SplitTime.create!(effort: @effort9, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 12000)
      SplitTime.create!(effort: @effort9, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 20000)
      SplitTime.create!(effort: @effort9, split: @split6, bitkey: SubSplit::IN_BITKEY, time_from_start: 30000)
      SplitTime.create!(effort: @effort9, split: @split4, bitkey: SubSplit::OUT_BITKEY, time_from_start: 22000)

      SplitTime.create!(effort: @effort10, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort10, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 40240)
      SplitTime.create!(effort: @effort10, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 4300)
      SplitTime.create!(effort: @effort10, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 11000)
      SplitTime.create!(effort: @effort10, split: @split4, bitkey: SubSplit::OUT_BITKEY, time_from_start: 11100)
      SplitTime.create!(effort: @effort10, split: @split6, bitkey: SubSplit::IN_BITKEY, time_from_start: 17600)

      SplitTime.create!(effort: @effort11, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort11, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 6800)
      SplitTime.create!(effort: @effort11, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 6800)
      SplitTime.create!(effort: @effort11, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 24000)
      SplitTime.create!(effort: @effort11, split: @split4, bitkey: SubSplit::OUT_BITKEY, time_from_start: 24200)
      SplitTime.create!(effort: @effort11, split: @split6, bitkey: SubSplit::IN_BITKEY, time_from_start: 33000)

      SplitTime.create!(effort: @effort12, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort12, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 5300)
      SplitTime.create!(effort: @effort12, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 5400)
      SplitTime.create!(effort: @effort12, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 12500)
      SplitTime.create!(effort: @effort12, split: @split4, bitkey: SubSplit::OUT_BITKEY, time_from_start: 12550)
      SplitTime.create!(effort: @effort12, split: @split6, bitkey: SubSplit::IN_BITKEY, time_from_start: 23232)

      SplitTime.create!(effort: @effort13, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort13, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 4900)
      SplitTime.create!(effort: @effort13, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 4940)
      SplitTime.create!(effort: @effort13, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 13400)
      SplitTime.create!(effort: @effort13, split: @split4, bitkey: SubSplit::OUT_BITKEY, time_from_start: 14300)
      SplitTime.create!(effort: @effort13, split: @split6, bitkey: SubSplit::IN_BITKEY, time_from_start: 19800)

      efforts = Effort.all
      DataStatusService.set_data_status(efforts)

    end

    it 'should accept a single effort as a parameter' do
      DataStatusService.set_data_status(@effort1)
    end

    it 'should accept an array of efforts as a parameter' do
      DataStatusService.set_data_status([@effort1, @effort2])
    end

    it 'should accept an ActiveRecord relation as a parameter' do
      efforts = Effort.female
      DataStatusService.set_data_status(efforts)
    end

    it 'should set the data status of the efforts to the lowest status of the split times' do
      expect(Effort.where(bib_number: 1).first.data_status).to eq('bad')
      expect(Effort.where(bib_number: 2).first.data_status).to eq('bad')
      expect(Effort.where(bib_number: 3).first.data_status).to eq('good')
      expect(Effort.where(bib_number: 8).first.data_status).to eq('good')
      expect(Effort.where(bib_number: 11).first.data_status).to eq('questionable')
    end

    it 'should set the data status of negative segment times to bad' do
      expect(@effort1.split_times.where(split: @split4, bitkey: SubSplit::OUT_BITKEY).first.bad?).to eq(true)
      expect(@effort4.split_times.where(split: @split2, bitkey: SubSplit::OUT_BITKEY).first.bad?).to eq(true)
    end

    it 'should look past bad data points to the previous valid data point to calculate data status' do
      expect(@effort2.split_times.where(split: @split6, bitkey: SubSplit::IN_BITKEY).first.questionable?).to eq(true)
      expect(@effort10.split_times.where(split: @split2, bitkey: SubSplit::OUT_BITKEY).first.good?).to eq(true)

    end

    it 'should set the data status of split_times properly' do
      expect(@effort1.split_times.good.count).to eq(5)
      expect(@effort1.split_times.bad.count).to eq(1)
      expect(@effort2.split_times.good.count).to eq(2)
      expect(@effort2.split_times.questionable.count).to eq(1)
      expect(@effort2.split_times.bad.count).to eq(3)
      expect(@effort4.split_times.good.count).to eq(4)
      expect(@effort4.split_times.bad.count).to eq(2)
      expect(@effort11.split_times.good.count).to eq(4)
      expect(@effort11.split_times.questionable.count).to eq(2)
      expect(@effort11.split_times.bad.count).to eq(0)
    end

    it 'should set the data status of non-zero start splits to bad' do
      expect(@effort4.split_times.where(split: @split1, bitkey: SubSplit::IN_BITKEY).first.data_status).to eq('bad')
    end

    it 'should set the data status of impossibly fast segments to bad' do
      expect(@effort2.split_times.where(split: @split2, bitkey: SubSplit::IN_BITKEY).first.bad?).to eq(true)
      expect(@effort2.split_times.where(split: @split2, bitkey: SubSplit::OUT_BITKEY).first.bad?).to eq(true)
    end

    it 'should set the data status of impossibly slow segments to bad' do
      expect(@effort2.split_times.where(split: @split4, bitkey: SubSplit::OUT_BITKEY).first.bad?).to eq(true)
      expect(@effort10.split_times.where(split: @split2, bitkey: SubSplit::IN_BITKEY).first.bad?).to eq(true)
    end

    it 'should set the data status of splits correctly even if missing prior splits' do
      expect(@effort6.split_times.where(split: @split4, bitkey: SubSplit::IN_BITKEY).first.good?).to eq(true)
      expect(@effort8.split_times.where(split: @split6, bitkey: SubSplit::IN_BITKEY).first.good?).to eq(true)
    end
  end


end
