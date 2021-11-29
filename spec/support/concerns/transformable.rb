# frozen_string_literal: true

RSpec.shared_examples_for 'transformable' do
  subject { described_class.new(attributes) }

  describe '#add_country_from_state_code!' do
    context 'when the state_code attribute is a US state' do
      let(:attributes) { {state_code: 'NY'} }

      it 'adds a US country code' do
        subject.add_country_from_state_code!
        expect(subject[:country_code]).to eq('US')
      end
    end

    context 'when the state_code attribute is a Canadian province' do
      let(:attributes) { {state_code: 'BC'} }

      it 'adds a CA country code' do
        subject.add_country_from_state_code!
        expect(subject[:country_code]).to eq('CA')
      end
    end

    context 'when the state_code attribute is not a US state or Canadian province' do
      let(:attributes) { {state_code: 'XX'} }

      it 'Does not add a country code' do
        subject.add_country_from_state_code!
        expect(subject[:country_code]).to be_nil
      end
    end
  end

  describe "#add_date_to_time!" do
    examples =
      [
        {time_string: "08:30:30", date: "2020-07-15", expected: "2020-07-15 08:30:30"},
        {time_string: "08:30:30", date: "2020-07-15 10:00:00", expected: "2020-07-15 08:30:30"},
        {time_string: "08:30:30", date: "2020-07-15 10:00:00".to_datetime, expected: "2020-07-15 08:30:30"},
        {time_string: "08:30:30", date: "2020-07-15".to_date, expected: "2020-07-15 08:30:30"},
        {time_string: "08:30:30", date: "2020-07-15".to_datetime, expected: "2020-07-15 08:30:30"},
        {time_string: "2020-07-10 08:00:00", date: "2020-07-15", expected: "2020-07-10 08:00:00"},
        {time_string: "hello", date: "2020-07-15", expected: "hello"},
        {time_string: "", date: "2020-07-15", expected: ""},
        {time_string: nil, date: "2020-07-15", expected: nil},
      ]

    examples.each do |example|
      time_string = example[:time_string]
      date = example[:date]
      expected = example[:expected]

      context "when time string is #{time_string} and date is #{date}" do
        let(:attributes) { {scheduled_start_time_local: time_string} }
        before { subject.add_date_to_time!(:scheduled_start_time_local, date) }
        it { expect(subject[:scheduled_start_time_local]).to eq(expected) }
      end
    end
  end

  describe '#align_split_distance!' do
    let!(:course_distances) { [0, 3000, 6000, 9000] }

    context 'when distance_from_start attribute aligns exactly with a provided distance' do
      let(:attributes) { {distance_from_start: 3000} }

      it 'makes no change to distance_from_start attribute' do
        subject.align_split_distance!(course_distances)
        expect(subject[:distance_from_start]).to eq(3000)
      end
    end

    context 'when distance_from_start attribute is within 10 meters of a provided distance' do
      let(:attributes) { {distance_from_start: 2991} }

      it 'changes the distance_from_start attribute to that distance' do
        subject.align_split_distance!(course_distances)
        expect(subject[:distance_from_start]).to eq(3000)
      end
    end

    context 'when distance_from_start attribute is not within 10 meters of a provided distance' do
      let(:attributes) { {distance_from_start: 2900} }

      it 'makes no change to distance_from_start attribute' do
        subject.align_split_distance!(course_distances)
        expect(subject[:distance_from_start]).to eq(2900)
      end
    end
  end

  describe '#convert_split_distance!' do
    context 'when the provided attributes include distance' do
      let(:attributes) { {distance: 10} }

      it 'converts to meters, deletes the distance field, and creates a distance_from_start field' do
        subject.convert_split_distance!
        expect(subject[:distance_from_start]).to eq(16093)
        expect(subject[:distance]).to be_nil
      end
    end

    context 'when the provided attributes do not include distance' do
      let(:attributes) { {distance_from_start: 5000} }

      it 'makes no change to the distance_from_start field' do
        subject.convert_split_distance!
        expect(subject[:distance_from_start]).to eq(5000)
      end
    end
  end

  describe '#convert_start_offset!' do
    let(:attributes) { {start_offset: start_offset} }
    let(:event_start_time) { '2018-06-30 08:00:00'.in_time_zone('UTC') }
    before { subject.convert_start_offset!(event_start_time) }

    context 'when start_offset is an integer number of seconds' do
      let(:start_offset) { 120 }

      it 'sets scheduled_start_time equal to event start_time plus the start_offset' do
        expect(subject[:scheduled_start_time]).to eq(event_start_time + 120.seconds)
      end
    end

    context 'when start_offset is a string number of seconds' do
      let(:start_offset) { '120' }

      it 'sets scheduled_start_time equal to event start_time plus the start_offset' do
        expect(subject[:scheduled_start_time]).to eq(event_start_time + 120.seconds)
      end
    end

    context 'when start_offset is a string hh:mm:ss' do
      let(:start_offset) { '01:00:00' }

      it 'sets scheduled_start_time equal to event start_time plus the start_offset' do
        expect(subject[:scheduled_start_time]).to eq(event_start_time + 1.hour)
      end
    end

    context 'when start_offset is a string hh:mm:ss with many hours and minutes' do
      let(:start_offset) { '150:30:00' }

      it 'sets scheduled_start_time equal to event start_time plus the start_offset' do
        expect(subject[:scheduled_start_time]).to eq(event_start_time + 150.5.hours)
      end
    end

    context 'when start_offset is a string hh:mm' do
      let(:start_offset) { '01:00' }

      it 'sets scheduled_start_time equal to event start_time plus the start_offset' do
        expect(subject[:scheduled_start_time]).to eq(event_start_time + 1.hour)
      end
    end

    context 'when start_offset contains no numbers' do
      let(:start_offset) { 'hello' }

      it 'does not set scheduled_start_time' do
        expect(subject[:scheduled_start_time]).to be_nil
      end
    end

    context 'when start_offset contains a mix of numbers and letters' do
      let(:start_offset) { 'hello120' }

      it 'interprets the string based on the numbers' do
        expect(subject[:scheduled_start_time]).to eq(event_start_time + 120.seconds)
      end
    end

    context 'when start_offset is an empty string' do
      let(:start_offset) { '' }

      it 'does not set scheduled_start_time' do
        expect(subject[:scheduled_start_time]).to be_nil
      end
    end

    context 'when start_offset is nil' do
      let(:start_offset) { nil }

      it 'does not set scheduled_start_time' do
        expect(subject[:scheduled_start_time]).to be_nil
      end
    end
  end

  describe '#create_country_from_state!' do
    context 'when a state code from the United States exists but no country_code exists' do
      let(:attributes) { {state_code: 'NY'} }

      it 'adds country_code for the US' do
        subject.create_country_from_state!
        expect(subject[:country_code]).to eq('US')
      end
    end

    context 'when a state code from Canada exists but no country_code exists' do
      let(:attributes) { {state_code: 'BC'} }

      it 'adds country_code for the US' do
        subject.create_country_from_state!
        expect(subject[:country_code]).to eq('CA')
      end
    end
  end

  describe '#localize_datetime!' do
    let(:local_key) { :scheduled_start_time_local }
    let(:utc_key) { :scheduled_start_time }
    let(:attributes) { {local_key => local_time, time_zone_name: time_zone_name} }
    let(:local_time) { '2018-06-30 08:00:00' }
    let(:time_zone_name) { 'Mountain Time (US & Canada)' }

    before { subject.localize_datetime!(local_key, utc_key, time_zone_name) }

    context 'when local time and time zone are present' do
      it 'deletes the local time key and adds the utc time key with converted datetime' do
        expect(subject.to_h).to eq({utc_key => '2018-06-30 14:00:00', time_zone_name: time_zone_name})
      end
    end

    context 'when local time is not valid' do
      let(:local_time) { 'hello' }

      it 'deletes the local time key and does not set a utc time key' do
        expect(subject.to_h).to eq({time_zone_name: time_zone_name})
      end
    end

    context 'when local time is an empty string' do
      let(:local_time) { '' }

      it 'deletes the local time key and does not set a utc time key' do
        expect(subject.to_h).to eq({time_zone_name: time_zone_name})
      end
    end

    context 'when local time is nil' do
      let(:local_time) { nil }

      it 'deletes the local time key and does not set a utc time key' do
        expect(subject.to_h).to eq({time_zone_name: time_zone_name})
      end
    end

    context 'when time_zone_name is not valid' do
      let(:time_zone_name) { 'hello' }

      it 'deletes the local time key and does not create a utc time key' do
        expect(subject.to_h).to eq({time_zone_name: time_zone_name})
      end
    end

    context 'when time_zone_name is an empty string' do
      let(:time_zone_name) { '' }

      it 'deletes the local time key and does not create a utc time key' do
        expect(subject.to_h).to eq({time_zone_name: time_zone_name})
      end
    end

    context 'when time_zone_name is nil' do
      let(:time_zone_name) { nil }

      it 'deletes the local time key and does not create a utc time key' do
        expect(subject.to_h).to eq({time_zone_name: time_zone_name})
      end
    end
  end

  describe '#map_keys!' do
    context 'when all keys are in the object' do
      let(:attributes) { {name: 'Joe Hardman', sex: 'male'} }
      let(:map) { {name: :full_name, sex: :gender} }

      it 'changes keys according to the provided map' do
        subject.map_keys!(map)
        expect(subject.to_h.keys.sort).to eq([:full_name, :gender])
      end
    end

    context 'when some keys are not in the object' do
      let(:attributes) { {name: 'Joe Hardman', age: 29} }
      let(:map) { {name: :full_name, sex: :gender} }

      it 'ignores keys that are not found' do
        subject.map_keys!(map)
        expect(subject.to_h.keys.sort).to eq([:age, :full_name])
      end
    end

    context 'when mapped keys have nil values' do
      let(:attributes) { {name: nil, age: 29} }
      let(:map) { {name: :full_name} }

      it 'maps the headings correctly' do
        subject.map_keys!(map)
        expect(subject.to_h.keys.sort).to eq([:age, :full_name])
      end
    end
  end

  describe '#merge_attributes!' do
    let(:attributes) { {first_name: 'Joe', gender: 'male'} }

    context 'when merging attributes are disjoint from existing attributes' do
      let(:merging_attributes) { {last_name: 'Hardman', age: 55} }

      it 'merges existing attributes with merging attributes' do
        subject.merge_attributes!(merging_attributes)
        expect(subject.to_h).to eq({first_name: 'Joe', last_name: 'Hardman', gender: 'male', age: 55})
      end
    end

    context 'when merging attributes overlap with existing attributes' do
      let(:merging_attributes) { {first_name: 'Joseph', age: 55} }

      it 'gives precedence to merging attributes' do
        subject.merge_attributes!(merging_attributes)
        expect(subject.to_h).to eq({first_name: 'Joseph', gender: 'male', age: 55})
      end
    end
  end

  describe '#normalize_date!' do
    let(:attributes) { {birthdate: birthdate} }

    context 'when provided with an American mm/dd/yy format' do
      let(:birthdate) { '09/29/67' }

      it 'corrects the year to between 1920 and 2019' do
        subject.normalize_date!(:birthdate)
        expect(subject[:birthdate]).to eq('1967-09-29')
      end
    end

    context 'when provided with a two-digit year above the mod 100 of the current year' do
      let(:two_digit_year) { Date.today.year % 100 + 1 }
      let(:four_digit_year) { Date.today.year - 99 }
      let(:birthdate) { "09/29/#{two_digit_year}" }

      it 'assumes a year in the past' do
        subject.normalize_date!(:birthdate)
        expect(subject[:birthdate]).to eq("#{four_digit_year}-09-29")
      end
    end

    context 'when provided with a two-digit year equal to or lower than the mod 100 of the current year' do
      let(:two_digit_year) { Date.today.year % 100 }
      let(:four_digit_year) { Date.today.year }
      let(:birthdate) { "09/29/#{two_digit_year}" }

      it 'assumes the current year' do
        subject.normalize_date!(:birthdate)
        expect(subject[:birthdate]).to eq("#{four_digit_year}-09-29")
      end
    end

    context 'when provided with an integer' do
      let(:birthdate) { 27662 }

      it 'does not attempt to transform the value' do
        subject.normalize_date!(:birthdate)
        expect(subject[:birthdate]).to eq(27662)
      end
    end

    context 'when provided with a string that cannot be transformed into a date' do
      let(:birthdate) { 'hello' }

      it 'does not attempt to transform the value' do
        subject.normalize_date!(:birthdate)
        expect(subject[:birthdate]).to eq('hello')
      end
    end

    context 'when provided with nil' do
      let(:birthdate) { nil }

      it 'does not attempt to transform the value' do
        subject.normalize_date!(:birthdate)
        expect(subject[:birthdate]).to be_nil
      end
    end
  end

  describe '#normalize_datetime!' do
    let(:attributes) { {start_time: start_time} }

    context 'when provided with an American mm/dd/yy hh:mm:ss format' do
      let(:start_time) { '09/29/67 06:30:00' }

      it 'corrects the year to between 19xx and 20xx' do
        subject.normalize_datetime!(:start_time)
        expect(subject[:start_time]).to eq('1967-09-29 06:30:00')
      end
    end

    context 'when provided with a two-digit year above the mod 100 of the current year' do
      let(:two_digit_year) { Date.today.year % 100 + 1 }
      let(:four_digit_year) { Date.today.year - 99 }
      let(:start_time) { "09/29/#{two_digit_year} 06:30:00" }

      it 'assumes a year in the past' do
        subject.normalize_datetime!(:start_time)
        expect(subject[:start_time]).to eq("#{four_digit_year}-09-29 06:30:00")
      end
    end

    context 'when provided with a two-digit year equal to or lower than the mod 100 of the current year' do
      let(:two_digit_year) { Date.today.year % 100 }
      let(:four_digit_year) { Date.today.year }
      let(:start_time) { "09/29/#{two_digit_year} 06:30:00" }

      it 'assumes the current year' do
        subject.normalize_datetime!(:start_time)
        expect(subject[:start_time]).to eq("#{four_digit_year}-09-29 06:30:00")
      end
    end

    context 'when provided with an integer' do
      let(:start_time) { 27662 }

      it 'does not attempt to transform the value' do
        subject.normalize_datetime!(:start_time)
        expect(subject[:start_time]).to eq(27662)
      end
    end

    context 'when provided with a string that cannot be transformed into a date' do
      let(:start_time) { 'hello' }

      it 'does not attempt to transform the value' do
        subject.normalize_datetime!(:start_time)
        expect(subject[:start_time]).to eq('hello')
      end
    end

    context 'when provided with nil' do
      let(:start_time) { nil }

      it 'does not attempt to transform the value' do
        subject.normalize_datetime!(:start_time)
        expect(subject[:start_time]).to be_nil
      end
    end
  end

  describe '#normalize_country_code!' do
    context 'when provided with ISO 3166 2-character code' do
      let(:attributes) { {country_code: 'US'} }

      it 'does nothing to the value' do
        subject.normalize_country_code!
        expect(subject[:country_code]).to eq('US')
      end
    end

    context 'when provided with ISO 3166 3-character country codes' do
      let(:attributes) { {country_code: 'JPN'} }

      it 'converts it to ISO 3166 2-character codes' do
        subject.normalize_country_code!
        expect(subject[:country_code]).to eq('JP')
      end
    end

    context 'when provided with an official name' do
      let(:attributes) { {country_code: 'United States'} }

      it 'converts it to ISO 3166 2-character codes' do
        subject.normalize_country_code!
        expect(subject[:country_code]).to eq('US')
      end
    end

    context 'when provided with a nickname listed in /config/locales/en.yml:en:nicknames' do
      let(:attributes) { {country_code: 'England'} }

      it 'converts it to ISO 3166 2-character codes' do
        subject.normalize_country_code!
        expect(subject[:country_code]).to eq('GB')
      end
    end

    context 'when provided with invalid country data' do
      let(:attributes) { {country_code: 'Neverland'} }

      it 'sets the value to nil' do
        subject.normalize_country_code!
        expect(subject[:country_code]).to eq(nil)
      end
    end
  end

  describe '#normalize_gender!' do
    context 'when existing gender starts with "M"' do
      let(:attributes) { {first_name: 'Joe', gender: 'M'} }

      it 'changes the value to "male"' do
        subject.normalize_gender!
        expect(subject[:gender]).to eq('male')
      end
    end

    context 'when existing gender starts with "F"' do
      let(:attributes) { {first_name: 'Joe', gender: 'F'} }

      it 'changes the value to "female"' do
        subject.normalize_gender!
        expect(subject[:gender]).to eq('female')
      end
    end

    context 'when existing gender starts with neither "M" nor "F"' do
      let(:attributes) { {first_name: 'Joe', gender: 'Hello'} }

      it 'changes the value to nil' do
        subject.normalize_gender!
        expect(subject[:gender]).to eq(nil)
      end
    end

    context 'when existing gender is not a string' do
      let(:attributes) { {first_name: 'Joe', gender: 1} }

      it 'changes the value to nil' do
        subject.normalize_gender!
        expect(subject[:gender]).to eq(nil)
      end
    end

    context 'when existing gender is an empty string' do
      let(:attributes) { {first_name: 'Joe', gender: ''} }

      it 'changes the value to nil' do
        subject.normalize_gender!
        expect(subject[:gender]).to eq(nil)
      end
    end

    context 'when existing gender does not exist' do
      let(:attributes) { {first_name: 'Joe', age: 55} }

      it 'does not set a value' do
        subject.normalize_gender!
        expect(subject[:gender]).to eq(nil)
      end
    end
  end

  describe '#normalize_state_code' do
    context 'when no country is provided for context' do
      let(:attributes) { {state_code: 'State Of Confusion'} }

      it 'does nothing to the value' do
        subject.normalize_state_code!
        expect(subject[:state_code]).to eq('State Of Confusion')
      end
    end

    context 'when provided with a country and an ISO 3166 2-character code' do
      let(:attributes) { {country_code: 'CA', state_code: 'BC'} }

      it 'does nothing to the value' do
        subject.normalize_state_code!
        expect(subject[:state_code]).to eq('BC')
      end
    end

    context 'when provided with a country and a named state within that country' do
      let(:attributes) { {country_code: 'US', state_code: 'Colorado'} }

      it 'converts the value to a 2-character ISO 3166 code' do
        subject.normalize_state_code!
        expect(subject[:state_code]).to eq('CO')
      end
    end

    context 'when provided with a country that has subregions but the state_code does not resolve' do
      let(:attributes) { {country_code: 'US', state_code: 'Private Island of Joe'} }

      it 'does nothing to the value' do
        subject.normalize_state_code!
        expect(subject[:state_code]).to eq('Private Island of Joe')
      end
    end
  end

  describe '#delete_nil_keys!' do
    context 'when a single key exists and value is nil' do
      let(:attributes) { {first_name: 'Joe', start_time: nil, gender: nil} }

      it 'deletes the keys' do
        expect(subject.to_h).to eq(attributes)
        subject.delete_nil_keys!(:gender)
        expect(subject.to_h).to eq({first_name: 'Joe', start_time: nil})
      end
    end

    context 'when multiple keys exist and values are nil' do
      let(:attributes) { {first_name: 'Joe', start_time: nil, gender: nil} }

      it 'deletes the keys' do
        expect(subject.to_h).to eq(attributes)
        subject.delete_nil_keys!(:start_time, :gender)
        expect(subject.to_h).to eq({first_name: 'Joe'})
      end
    end

    context 'when any value is not nil' do
      let(:attributes) { {first_name: 'Joe', start_time: nil, gender: nil} }

      it 'deletes the keys' do
        expect(subject.to_h).to eq(attributes)
        subject.delete_nil_keys!(:first_name, :gender)
        expect(subject.to_h).to eq({first_name: 'Joe', start_time: nil})
      end
    end
  end

  describe '#fill_blank_values!' do
    context 'when keys exist and are nil' do
      let(:attributes) { {first_name: 'Joe', start_time: nil, gender: nil} }

      it 'sets the keys to the given values' do
        subject.fill_blank_values!(start_time: '', gender: 'male')
        expect(subject.to_h).to eq({first_name: 'Joe', start_time: '', gender: 'male'})
      end
    end

    context 'when keys exist and are blank' do
      let(:attributes) { {first_name: 'Joe', start_time: '', gender: ''} }

      it 'sets the keys to the given values' do
        subject.fill_blank_values!(start_time: '', gender: 'male')
        expect(subject.to_h).to eq({first_name: 'Joe', start_time: '', gender: 'male'})
      end
    end

    context 'when keys exist and are present' do
      let(:attributes) { {first_name: 'Joe', start_time: '2017-07-01 06:00:00', gender: 'male'} }

      it 'does not change the keys' do
        subject.fill_blank_values!(start_time: '', gender: 'female')
        expect(subject.to_h).to eq({first_name: 'Joe', start_time: '2017-07-01 06:00:00', gender: 'male'})
      end
    end

    context 'when keys do not exist' do
      let(:attributes) { {first_name: 'Joe'} }

      it 'does not add the keys' do
        subject.fill_blank_values!(start_time: '', gender: 'male')
        expect(subject.to_h).to eq({first_name: 'Joe'})
      end
    end
  end

  describe '#slice_permitted!' do
    context 'when provided with a set of permitted parameters' do
      let(:attributes) { {first_name: 'Joe', age: 55, role: 'admin'} }
      let(:permitted) { [:first_name, :last_name, :age] }

      it 'removes attributes that are not in the provided permitted parameters' do
        subject.slice_permitted!(permitted)
        expect(subject.to_h).to eq({first_name: 'Joe', age: 55})
      end
    end

    context 'when not provided with a set of permitted parameters' do
      let(:attributes) { {record_type: :effort, first_name: 'Joe', age: 55, role: 'admin'} }

      it 'removes attributes that are not found in the params class for the record_type' do
        allow(EffortParameters).to receive(:permitted).and_return([:first_name, :last_name, :age])
        subject.slice_permitted!
        expect(subject.to_h).to eq({first_name: 'Joe', age: 55})
      end
    end
  end

  describe '#split_field!' do
    let(:attributes) { {full_name: full_name} }

    context 'when full_name key contains a two-word name' do
      let(:full_name) { 'Joe Hardman' }

      it 'assigns the first word of the provided string to first_name and the last word to last_name' do
        expected_first_name = 'Joe'
        expected_last_name = 'Hardman'
        verify_split(expected_first_name, expected_last_name)
      end
    end

    context 'when provided with a three-word name' do
      let(:full_name) { 'Billy Bob Thornton' }

      it 'assigns the first two words of the provided string to first_name and the last word to last_name' do
        expected_first_name = 'Billy Bob'
        expected_last_name = 'Thornton'
        verify_split(expected_first_name, expected_last_name)
      end
    end

    context 'when provided with a one-word name' do
      let(:full_name) { 'Johnny' }

      it 'assigns the name to first_name' do
        expected_first_name = 'Johnny'
        expected_last_name = nil
        verify_split(expected_first_name, expected_last_name)
      end
    end

    context 'when provided with an empty string' do
      let(:full_name) { '' }

      it 'assigns nil to both first_name and last_name' do
        expected_first_name = nil
        expected_last_name = nil
        verify_split(expected_first_name, expected_last_name)
      end
    end

    context 'when provided with nil' do
      let(:full_name) { nil }

      it 'assigns nil to both first_name and last_name' do
        expected_first_name = nil
        expected_last_name = nil
        verify_split(expected_first_name, expected_last_name)
      end
    end

    def verify_split(expected_first_name, expected_last_name)
      subject.split_field!(:full_name, :first_name, :last_name)
      expect(subject[:first_name]).to eq(expected_first_name)
      expect(subject[:last_name]).to eq(expected_last_name)
    end
  end

  describe '#strip_white_space!' do
    let(:attributes) { {'time_in' => ' 09:22 ', 'time_out' => '  10:12  '} }

    it 'removes white space from attribute values' do
      subject.strip_white_space!
      expect(subject[:time_in]).to eq('09:22')
      expect(subject[:time_out]).to eq('10:12')
    end
  end

  describe '#underscore_keys!' do
    let(:attributes) { {firstName: 'Joe', lastName: 'Hardman'} }

    it 'changes keys according to the provided map' do
      subject.underscore_keys!
      expect(subject.to_h.keys.sort).to eq([:first_name, :last_name])
    end
  end
end
