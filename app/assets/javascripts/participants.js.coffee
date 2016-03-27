$ ->
  $('select#participant_country_code').change (event) ->
    select_wrapper = $('#participant_state_code_wrapper')

    $('select', select_wrapper).attr('disabled', true)

    country_code = $(this).val()

    url = "/participants/subregion_options?parent_region=#{country_code}"
    select_wrapper.load(url)

  $('select#locale').change (event) ->
    $(@).closest('form').submit()