# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::StagingController do
  login_admin

  describe '#get_countries' do
    it 'returns a successful 200 response' do
      get :get_countries
      expect(response).to be_successful
    end

    it 'returns a set of country data that includes all Carmen countries' do
      country_count = Carmen::Country.all.size
      get :get_countries
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['countries'].size).to eq(country_count)
    end

    it 'returns subregions for each country that include all Carmen subregions for that country' do
      us = Carmen::Country.coded('US')
      subregion_count = us.subregions.reject { |subregion| subregion.type == 'apo' }.size
      get :get_countries
      parsed_response = JSON.parse(response.body)
      us_subregions = parsed_response['countries'].find { |country| country['code'] == 'US' }['subregions']
      expect(us_subregions.size).to eq(subregion_count)
    end
  end

  describe '#get_time_zones' do
    it 'returns a successful 200 response' do
      get :get_time_zones
      expect(response).to be_successful
    end

    it 'returns an array of all ActiveSupport::TimeZone names and offsets' do
      tz_count = ActiveSupport::TimeZone.all.size
      get :get_time_zones
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['time_zones'].size).to eq(tz_count)
    end

    it 'returns both names and formatted offsets for each time zone' do
      eastern_time_zone_name = 'Eastern Time (US & Canada)'
      eastern = ActiveSupport::TimeZone[eastern_time_zone_name]
      get :get_time_zones
      parsed_response = JSON.parse(response.body)
      eastern_response = parsed_response['time_zones'].find { |tz| tz.first == eastern_time_zone_name }
      expect(eastern_response.last).to eq(eastern.formatted_offset)
    end
  end

  describe '#post_event_course_org' do
    let(:event) { create(:event, event_group: event_group, course: course) }
    let(:event_group) { create(:event_group, organization: organization) }
    let(:course) { create(:course) }
    let(:organization) { create(:organization) }
    let(:event_id) { event.to_param }
    let(:new_event_indicator) { 'new' }

    let(:existing_event_params) { event.attributes.with_indifferent_access.slice(*EventParameters.permitted) }
    let(:existing_event_group_params) { event_group.attributes.with_indifferent_access.slice(*EventGroupParameters.permitted) }
    let(:existing_course_params) { course.attributes.with_indifferent_access.slice(*CourseParameters.permitted) }
    let(:existing_organization_params) { organization.attributes.with_indifferent_access.slice(*OrganizationParameters.permitted) }

    let(:updated_event_params) { {} }
    let(:updated_event_group_params) { {} }
    let(:updated_course_params) { {} }
    let(:updated_organization_params) { {} }

    let(:params) { {event: event_params, event_group: event_group_params, course: course_params, organization: organization_params} }

    context 'when an existing event_id is provided' do
      let(:event_params) { existing_event_params.merge(updated_event_params) }
      let(:event_group_params) { existing_event_group_params.merge(updated_event_group_params) }
      let(:course_params) { existing_course_params.merge(updated_course_params) }
      let(:organization_params) { existing_organization_params.merge(updated_organization_params) }

      it 'returns a successful 200 response' do
        status, _ = post_with_params(event_id, params)

        expect(status).to eq(200)
      end

      context 'when attributes are provided for an existing organization' do
        let(:updated_organization_params) { {name: 'Updated Organization Name', description: 'Updated organization description'} }

        it 'updates provided attributes for an existing organization' do
          status, resources = post_with_params(event_id, params)
          expected_attributes = {organization: updated_organization_params}

          expect(status).to eq(200)
          validate_response(resources, expected_attributes)
        end
      end

      context 'when attributes are provided for an existing course' do
        let(:updated_course_params) { {name: 'Updated Course Name', description: 'Updated course description'} }

        it 'updates provided attributes for an existing course' do
          status, resources = post_with_params(event_id, params)
          expected_attributes = {course: updated_course_params}

          expect(status).to eq(200)
          validate_response(resources, expected_attributes)
        end
      end

      context 'when attributes are provided for an existing event' do
        let(:updated_event_params) { {short_name: 'Updated Short Name', laps_required: 3} }

        it 'updates provided attributes for an existing event' do
          status, resources = post_with_params(event_id, params)
          expected_attributes = {event: updated_event_params}

          expect(status).to eq(200)
          validate_response(resources, expected_attributes)
        end
      end

      context 'when attributes are provided for an existing event_group' do
        let(:new_event_group_params) { {name: 'Updated Event Group Name'} }

        it 'updates provided attributes for the existing event_group' do
          skip 'until front end is fully event_group aware'

          status, resources = post_with_params(event_id, params)
          expected_attributes = {event_group: updated_event_group_params}

          expect(status).to eq(200)
          validate_response(resources, expected_attributes)
        end
      end
    end

    context 'when a new event_id is provided' do
      let(:new_event_params) { {short_name: '50M', start_time: '2017-03-01 06:00:00', laps_required: 1, home_time_zone: 'Pacific Time (US & Canada)'} }
      let(:new_event_group_params) { {name: 'New Event Name'} }
      let(:new_course_params) { {name: 'New Course Name', description: 'New course description.'} }
      let(:new_organization_params) { {name: 'New Organization Name'} }
      let(:event_id) { new_event_indicator }

      context 'when the event and event_group are new but the course and organization already exist' do
        let(:event_params) { new_event_params }
        let(:event_group_params) { new_event_group_params }
        let(:course_params) { existing_course_params }
        let(:organization_params) { existing_organization_params }

        it 'returns a successful 200 response' do
          status, _ = post_with_params(event_id, params)

          expect(status).to eq(200)
        end

        it 'creates an event and event_group using provided parameters and associates existing course and organization' do
          status, resources = post_with_params(event_id, params)
          expected_attributes = {event: new_event_params, event_group: new_event_group_params}

          expect(status).to eq(200)
          validate_response(resources, expected_attributes)
          expect(resources[:event].slug).to eq("#{new_event_group_params[:name]} #{new_event_params[:short_name]}".parameterize)
        end
      end

      context 'when the event is new but the event_group, course, and organization already exist' do
        let(:event_params) { new_event_params }
        let(:event_group_params) { existing_event_group_params }
        let(:course_params) { existing_course_params }
        let(:organization_params) { existing_organization_params }

        it 'creates an event using provided parameters and associates existing event_group, course, and organization' do
          skip 'until front end is fully event_group aware'

          status, resources = post_with_params(event_id, params)
          expected_attributes = {event: new_event_params, event_group: existing_event_group_params, course: existing_course_params, organization: existing_organization_params}

          expect(status).to eq(200)
          validate_response(resources, expected_attributes)
          expect(resources[:event].slug).to eq("#{existing_event_group_params[:name]} (#{new_event_params[:short_name]})".parameterize)
        end
      end

      context 'when the event_group, course, and organization are new' do
        let(:event_params) { new_event_params }
        let(:event_group_params) { new_event_group_params }
        let(:course_params) { new_course_params }
        let(:organization_params) { new_organization_params }

        it 'creates an event using provided parameters and associates newly created event_group, course, and organization' do
          status, resources = post_with_params(event_id, params)
          expected_attributes = {event: new_event_params, event_group: new_event_group_params}

          expect(status).to eq(200)
          validate_response(resources, expected_attributes)
          expect(resources[:event].slug).to eq("#{new_event_group_params[:name]} (#{new_event_params[:short_name]})".parameterize)
        end
      end

      context 'when the event cannot be created' do
        let(:event_params) { new_event_params.except(:start_time) }
        let(:event_group_params) { new_event_group_params }
        let(:course_params) { new_course_params }
        let(:organization_params) { new_organization_params }

        it 'returns a bad request message with descriptive errors and provided data and creates no resources' do
          status, _, parsed_response = post_with_params(event_id, params)
          expected_errors = [/Start time can't be blank/]

          expect(status).to eq(422)
          validate_errors(parsed_response, expected_errors)
          validate_no_resources_created
        end
      end

      context 'when the course cannot be created' do
        let(:event_params) { new_event_params }
        let(:event_group_params) { new_event_group_params }
        let(:course_params) { new_course_params.except(:name) }
        let(:organization_params) { new_organization_params }

        it 'returns a bad request message with descriptive errors and provided data and creates no resources' do
          status, _, parsed_response = post_with_params(event_id, params)
          expected_errors = [/Name can't be blank/]

          expect(status).to eq(422)
          validate_errors(parsed_response, expected_errors)
          validate_no_resources_created
        end
      end

      context 'when the organization cannot be created' do
        let(:event_params) { new_event_params }
        let(:event_group_params) { new_event_group_params }
        let(:course_params) { new_course_params }
        let(:organization_params) { new_organization_params.except(:name) }

        it 'returns a bad request message with descriptive errors and provided data and creates no resources' do
          status, _, parsed_response = post_with_params(event_id, params)
          expected_errors = [/Name can't be blank/]

          expect(status).to eq(422)
          validate_errors(parsed_response, expected_errors)
          validate_no_resources_created
        end
      end
    end

    def post_with_params(event_id, params)
      passed_params = {id: event_id,
                         event_group: params[:event_group],
                         event: params[:event],
                         course: params[:course],
                         organization: params[:organization]}
      post :post_event_course_org, params: passed_params

      status = response.status
      parsed_response = JSON.parse(response.body)

      if status == 200
        resources = {event: Event.find_by(id: parsed_response['event']['id']),
                     event_group: EventGroup.find_by(id: parsed_response['event_group']['id']),
                     course: Course.find_by(id: parsed_response['course']['id']),
                     organization: Organization.find_by(id: parsed_response['organization']['id'])}
      else
        resources = {}
      end

      [status, resources, parsed_response]
    end

    def validate_response(resources, expected_attributes)
      event = resources[:event]
      event_group = resources[:event_group]
      course = resources[:course]
      organization = resources[:organization]

      expect(event.event_group_id).to eq(event_group.id)
      expect(event.course_id).to eq(course.id)
      expect(event_group.organization_id).to eq(organization.id)

      expected_attributes.each do |class_name, attributes|
        attributes.each_key do |attribute_key|
          expect(resources[class_name].attributes.with_indifferent_access[attribute_key])
              .to eq(attributes[attribute_key])
        end
      end
    end

    def validate_errors(parsed_response, expected_errors)
      message_array = parsed_response['errors'].flat_map { |error| error['detail']['messages'] }

      expected_errors.each do |error_text|
        expect(message_array).to include(error_text)
      end
    end

    def validate_no_resources_created
      expect(Event.count).to eq(11)
      expect(Course.count).to eq(8)
      expect(Organization.count).to eq(4)
      expect(EventGroup.count).to eq(8)
    end
  end

  describe '#update_event_visibility' do
    subject(:make_request) { patch :update_event_visibility, params: {id: event.to_param, status: status} }
    let(:event_group) { event_groups(:dirty_30) }
    let(:organization) { event_group.organization }
    let(:event) { event_group.events.first }

    context 'when params[:status] == "public"' do
      let(:status) { 'public' }

      it 'returns a successful 200 response' do
        make_request
        expect(response).to be_successful
      end

      it 'sets concealed status of the event_group, organization, and people to false' do
        preset_concealed(true)

        make_request

        event_group.reload
        organization.reload

        expect(event_group.concealed).to eq(false)
        expect(organization.concealed).to eq(false)
        people = event_group.events.flat_map { |event| event.efforts.map(&:person) }.compact
        people.each do |person|
          expect(person.concealed).to eq(false)
        end
      end
    end

    context 'when params[:status] == "private"' do
      let(:event_group) { event_groups(:ramble) }
      let(:status) { 'private' }

      it 'returns a successful 200 response' do
        make_request
        expect(response).to be_successful
      end

      it 'sets concealed status of the event_group, organization, and people to true' do
        preset_concealed(false)

        make_request

        event_group.reload
        organization.reload

        expect(event_group.concealed).to eq(true)
        expect(organization.concealed).to eq(true)
        people = event_group.events.flat_map { |event| event.efforts.map(&:person) }.compact
        people.each do |person|
          expect(person.concealed).to eq(true)
        end
      end

      context 'for people that have other visible efforts' do
        let(:event_group) { event_groups(:dirty_30) }

        it 'does not make them private' do
          preset_concealed(false)

          make_request

          event_group.reload
          organization.reload
          expect(event_group.concealed).to eq(true)
          expect(organization.concealed).to eq(false)
          people = event_group.events.flat_map { |event| event.efforts.map(&:person) }.compact

          people.each do |person|
            if person.efforts.size == 1
              expect(person.concealed).to eq(true)
            else
              expect(person.concealed).to eq(false)
            end
          end
        end
      end

      context 'when params[:status] is not "public" or "private"' do
        it 'returns a bad request response' do
          patch :update_event_visibility, params: {id: event.to_param, status: 'random'}
          expect(response).to be_bad_request
        end
      end

      context 'when the event_id does not exist' do
        it 'returns a not found response' do
          patch :update_event_visibility, params: {id: 123, status: 'public'}
          expect(response).to be_not_found
        end
      end
    end

    def preset_concealed(boolean)
      event_group.update(concealed: boolean)
      organization.update(concealed: boolean)
      people = event_group.events.flat_map { |event| event.efforts.map(&:person) }.compact
      people.each { |person| person.update(concealed: boolean) }
    end
  end
end
