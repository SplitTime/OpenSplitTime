$('.events.stage').ready(function () {
        $('#file-efforts-with-times').on("change", function () {
            $('#submit-efforts-with-times').prop('disabled', !$(this).val());
        });

        $('#file-efforts-with-military-times').on("change", function () {
            $('#submit-efforts-with-military-times').prop('disabled', !$(this).val());
        });
    }
);
