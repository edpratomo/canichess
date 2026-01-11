# from siblksdb-v1
custom_field_error_2 = Proc.new do |html_tag, instance|
  html = %(<div class="field_with_errors">#{html_tag}</div>).html_safe
  # add nokogiri gem to Gemfile
  elements = Nokogiri::HTML::DocumentFragment.parse(html_tag).css "label, input"
  elements.each do |e|
    if e.node_name.eql? 'label'
      # html = %(<div class="clearfix error">#{e}</div>).html_safe
      html = "#{e}".html_safe
    elsif e.node_name.eql? 'input'
      if instance.error_message.kind_of?(Array)
        html = %(<div class="field_with_errors">#{html_tag}<span class="help-inline">&nbsp;#{instance.error_message.join(',')}</span></div>).html_safe
      else
        html = %(<div class="field_with_errors">#{html_tag}<span class="help-inline">&nbsp;#{instance.error._message}</span></div>).html_safe
      end
    end
  end
  html
end

custom_field_error = Proc.new do |html_tag, instance|
  html = %(<div class="field_with_errors">#{html_tag}</div>).html_safe
  # add nokogiri gem to Gemfile
  elements = Nokogiri::HTML::DocumentFragment.parse(html_tag).css "label, input"
  elements.each do |e|
    if e.node_name.eql? 'label'
      # html = %(<div class="clearfix error">#{e}</div>).html_safe
      html = "#{e}".html_safe
    elsif e.node_name.eql? 'input'
      errors = instance.error_message
      if errors.present?
        error_text = Array(errors).join(', ')
        html =<<-HTML.html_safe
          <div class="is-invalid">
            #{html_tag}
            <div class="invalid-feedback d-block">
              #{error_text}
            </div>
          </div>
        HTML
      end
    end
  end
  html
end

ActionView::Base.field_error_proc = custom_field_error
