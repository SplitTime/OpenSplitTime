$('.efforts.show').ready(function () {
        $('#file-effort-photo').on("change", function () {
            $('#submit-effort-photo').prop('disabled', !$(this).val());
        });
    }
);
