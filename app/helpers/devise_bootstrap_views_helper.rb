module DeviseBootstrapViewsHelper
    def bootstrap_devise_error_messages!
      return '' if resource.errors.empty?
  
      messages = resource.errors.full_messages.map { |message| content_tag(:li, message) }.join
      sentence = I18n.t(
        'errors.messages.not_saved',
        count: resource.errors.count,
        resource: resource.class.model_name.human.downcase
      )
  
      html = <<-HTML
<script type="text/javascript">
  $(function() {
    $.notify({
      title: '#{sentence}',
      message: '<ul>#{messages}</ul>'
    }, {
      type: 'danger',
      delay: 0 // Prevent automatic dismissal
    });
  });
</script>
      HTML
  
      html.html_safe
    end
  end