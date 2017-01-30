$('.events.stage').ready(function () {
        $('#file-splits').on("change", function () {
            $('#submit-splits').prop('disabled', !$(this).val());
        });

        $('#file-efforts-with-times').on("change", function () {
            $('#submit-efforts-with-times').prop('disabled', !$(this).val());
        });

        $('#file-efforts-with-military-times').on("change", function () {
            $('#submit-efforts-with-military-times').prop('disabled', !$(this).val());
        });

        $('#file-efforts-without-times').on("change", function () {
            $('#submit-efforts-without-times').prop('disabled', !$(this).val());
        });
    }
);