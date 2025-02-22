RSpec.shared_examples_for "matchable" do
  let(:model) { described_class }

  describe "#possible_matching_people" do
    it "returns records for which first and last names match, regardless of middle name and regardless of other attributes" do
      subject_attributes = { first_name: "Billy Bob", last_name: "Williams" }
      matching_attributes = [{ first_name: "Billy Bob", last_name: "Williams" }, { first_name: "Billy", last_name: "Bob Williams" }]
      differing_attributes = [{ first_name: "Joey", last_name: "Jones" }, { first_name: "Billy Bob", last_name: "Jones" }]
      verify_matching_people(subject_attributes, matching_attributes, differing_attributes)
    end

    it "for female efforts, returns records for which first name, age, gender, and state are the same, but last name differs" do
      subject_attributes = { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01", state_code: "CO" }
      matching_attributes = [
        { first_name: "Jane", last_name: "Goodall", gender: "female", birthdate: "1967-07-01", state_code: "CO" },
        { first_name: "Jane", last_name: "Eyre", gender: "female", birthdate: "1967-03-01", state_code: "CO" },
      ]
      differing_attributes = [
        { first_name: "Betty", last_name: "Boop", gender: "female", birthdate: "1967-07-01", state_code: "CO" },
        { first_name: "Jane", last_name: "Goodall", gender: "female", birthdate: "1999-07-01", state_code: "CO" },
        { first_name: "Jane", last_name: "Johnson", gender: "female", birthdate: "1967-07-01", state_code: "NM" },
      ]
      verify_matching_people(subject_attributes, matching_attributes, differing_attributes)
    end

    it "for male efforts, does not return records for which first name, age, gender, and state are the same, but last name differs" do
      subject_attributes = { first_name: "George", last_name: "Jetson", gender: "male", birthdate: "1967-07-01", state_code: "CO" }
      matching_attributes = [{ first_name: "George", last_name: "Jetson", gender: "male", birthdate: "1967-07-01", state_code: "CO" }]
      differing_attributes = [{ first_name: "George", last_name: "Clooney", gender: "male", birthdate: "1967-07-01", state_code: "CO" }]
      verify_matching_people(subject_attributes, matching_attributes, differing_attributes)
    end

    it "returns records for which last name, age, and gender are the same, but first name differs" do
      subject_attributes = { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01" }
      matching_attributes = [
        { first_name: "Judy", last_name: "Jetson", gender: "female", birthdate: "1967-07-01" },
        { first_name: "Jillian", last_name: "Jetson", gender: "female", birthdate: "1966-07-01" },
      ]
      differing_attributes = [{ first_name: "Judy", last_name: "Jetson", gender: "female", birthdate: "2001-07-01" }]
      verify_matching_people(subject_attributes, matching_attributes, differing_attributes)
    end

    it "does not return records where email is present in both records but differs" do
      subject_attributes = { first_name: "Jane", last_name: "Jetson", gender: "female", email: "jane@jetson.com" }
      matching_attributes = [
        { first_name: "Jane", last_name: "Jetson", gender: "female", email: nil },
        { first_name: "Jane", last_name: "Jetson", gender: "female", email: "jane@jetson.com" },
      ]
      differing_attributes = [{ first_name: "Jane", last_name: "Jetson", gender: "female", email: "jane@gmail.com" }]

      verify_matching_people(subject_attributes, matching_attributes, differing_attributes)
    end

    it "does not return records where phone is present in both records but differs" do
      subject_attributes = { first_name: "Jane", last_name: "Jetson", gender: "female", phone: "3035551212" }
      matching_attributes = [
        { first_name: "Jane", last_name: "Jetson", gender: "female", phone: nil },
        { first_name: "Jane", last_name: "Jetson", gender: "female", phone: "3035551212" },
      ]
      differing_attributes = [{ first_name: "Jane", last_name: "Jetson", gender: "female", phone: "8887776666" }]

      verify_matching_people(subject_attributes, matching_attributes, differing_attributes)
    end

    def verify_matching_people(subject_attributes, matching_attributes, differing_attributes)
      subject = described_class.new(subject_attributes)
      matching_people = matching_attributes.map { |attribute_set| create(:person, attribute_set) }
      differing_people = differing_attributes.map { |attribute_set| create(:person, attribute_set) }
      people = subject.possible_matching_people
      matching_people.each { |matching_person| expect(people).to include(matching_person) }
      differing_people.each { |differing_person| expect(people).not_to include(differing_person) }
    end
  end

  describe "#definitive_matching_person_by_birthdate" do
    it "returns a record for which first and last names and gender and birthdate match" do
      subject_attributes =
        { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01", email: "jane@jetson.com", phone: "3035551212" }
      matching_attributes =
        { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01" }

      differing_attributes = [
        { first_name: "Jeanie", last_name: "Jetson", gender: "female", birthdate: "1967-07-01" },
        { first_name: "Jane", last_name: "Gleason", gender: "female", birthdate: "1967-07-01" },
        { first_name: "Jane", last_name: "Jetson", gender: "male", birthdate: "1967-07-01" },
        { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1999-07-01" },
      ]
      verify_definitive_matching_person_by_birthdate(subject_attributes, matching_attributes, differing_attributes)
    end

    it "returns nil if more than one record is turned up" do
      subject_attributes = { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01" }
      matching_attributes = nil
      differing_attributes = [
        { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01", state_code: "NM" },
        { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01", state_code: "CO" },
      ]
      verify_definitive_matching_person_by_birthdate(subject_attributes, matching_attributes, differing_attributes)
    end
  end

  describe "#definitive_matching_person_by_email" do
    it "returns a record for which last name and gender and email match" do
      subject_attributes =
        { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01", email: "jane@jetson.com", phone: "3035551212" }
      matching_attributes =
        { first_name: "Janey", last_name: "Jetson", gender: "female", email: "jane@jetson.com" }

      differing_attributes = [
        { first_name: "Jane", last_name: "Gleason", gender: "female", email: "jane@jetson.com" },
        { first_name: "Jane", last_name: "Jetson", gender: "male", email: "jane@jetson.com" },
        { first_name: "Jane", last_name: "Jetson", gender: "female", email: "jane@gmail.com" },
      ]
      verify_definitive_matching_person_by_email(subject_attributes, matching_attributes, differing_attributes)
    end
  end

  describe "#definitive_matching_person_by_phone" do
    it "returns a record for which last name and gender and phone match" do
      subject_attributes =
        { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01", email: "jane@jetson.com", phone: "3035551212" }
      matching_attributes =
        { first_name: "Janey", last_name: "Jetson", gender: "female", phone: "+13035551212" }

      differing_attributes = [
        { first_name: "Jane", last_name: "Gleason", gender: "female", phone: "3035551212" },
        { first_name: "Jane", last_name: "Jetson", gender: "male", phone: "3035551212" },
        { first_name: "Jane", last_name: "Jetson", gender: "female", phone: "8887776666" },
      ]
      verify_definitive_matching_person_by_phone(subject_attributes, matching_attributes, differing_attributes)
    end
  end

  def verify_definitive_matching_person_by_birthdate(subject_attributes, matching_attributes, differing_attributes)
    subject = described_class.new(subject_attributes)
    matching_person = matching_attributes ? create(:person, matching_attributes) : nil
    differing_people = differing_attributes.map { |attribute_set| create(:person, attribute_set) }
    person = subject.definitive_matching_person_by_birthdate
    expect(person).to eq(matching_person)
    differing_people.each { |differing_person| expect(person).not_to eq(differing_person) }
  end

  def verify_definitive_matching_person_by_email(subject_attributes, matching_attributes, differing_attributes)
    subject = described_class.new(subject_attributes)
    matching_person = matching_attributes ? create(:person, matching_attributes) : nil
    differing_people = differing_attributes.map { |attribute_set| create(:person, attribute_set) }
    person = subject.definitive_matching_person_by_email
    expect(person).to eq(matching_person)
    differing_people.each { |differing_person| expect(person).not_to eq(differing_person) }
  end

  def verify_definitive_matching_person_by_phone(subject_attributes, matching_attributes, differing_attributes)
    subject = described_class.new(subject_attributes)
    matching_person = matching_attributes ? create(:person, matching_attributes) : nil
    differing_people = differing_attributes.map { |attribute_set| create(:person, attribute_set) }
    person = subject.definitive_matching_person_by_phone
    expect(person).to eq(matching_person)
    differing_people.each { |differing_person| expect(person).not_to eq(differing_person) }
  end

  describe "#exact_matching_person" do
    it "returns a record for which first and last names and gender match, and either state_code or age matches" do
      subject_attributes = { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01", state_code: "CO" }
      matching_attributes = subject_attributes
      differing_attributes = [
        { first_name: "Jeanie", last_name: "Jetson", gender: "female", birthdate: "1967-07-01", state_code: "CO" },
        { first_name: "Jane", last_name: "Gleason", gender: "female", birthdate: "1967-07-01", state_code: "CO" },
        { first_name: "Jane", last_name: "Jetson", gender: "male", birthdate: "1967-07-01", state_code: "CO" },
        { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1999-07-01", state_code: "NM" },
      ]
      verify_exact_matching_person(subject_attributes, matching_attributes, differing_attributes)
    end

    it "returns nil if more than one record is turned up" do
      subject_attributes = { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01", state_code: "CO" }
      matching_attributes = nil
      differing_attributes = [
        { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01", state_code: "NM" },
        { first_name: "Jane", last_name: "Jetson", gender: "female", birthdate: "1967-07-01", state_code: "CO" },
      ]
      verify_exact_matching_person(subject_attributes, matching_attributes, differing_attributes)
    end

    def verify_exact_matching_person(subject_attributes, matching_attributes, differing_attributes)
      subject = described_class.new(subject_attributes)
      matching_person = matching_attributes ? create(:person, matching_attributes) : nil
      differing_people = differing_attributes.map { |attribute_set| create(:person, attribute_set) }
      person = subject.exact_matching_person
      expect(person).to eq(matching_person)
      differing_people.each { |differing_person| expect(person).not_to eq(differing_person) }
    end
  end
end
