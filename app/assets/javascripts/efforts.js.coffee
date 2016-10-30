$ ->
  $('select#effort_country_code').change (event) ->
    select_wrapper = $('#effort_state_code_wrapper')

    $('select', select_wrapper).attr('disabled', true)

    country_code = $(this).val()

    url = "/efforts/subregion_options?parent_region=#{country_code}"
    select_wrapper.load(url)

  $('select#locale').change (event) ->
    $(@).closest('form').submit()
