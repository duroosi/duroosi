# Bootstrap implementation of theme related ui elements
module Themes::Bootstrap::BootstrapHelper 
  def css_container
    if @current_theme and @current_theme['fluid']
      "container-fluid"
    else
      "container"
    end
  end
  
  def css_columns(columns = 12)
    "col-md-#{columns}"
  end
  
  def css_align(direction)
    "pull-#{direction}"
  end
  
  def css_text(type)
    "text-#{type}"
  end
  
  def css_table(styles=[:hover])
    "table #{styles.map {|s| "table-#{s}"}.join(' ')}"
  end
  
  def css_button(*styles)
    'group'.in?(styles) ? 'btn-group' : "btn #{styles.map {|s| "btn-#{s}"}.join(' ')}"
  end
  
  def css_alert(style)
    "alert alert-#{style}"
  end
  
  def css_form(type)
    "form-#{type}"
  end
  
  def css_badge
    "badge"
  end
  
  def css_label(style)
    "label label-#{style}"
  end
  
  def css_nav(style)
    "nav nav-#{style}"
  end
  
  def css_breadcrumb
    "breadcrumb"
  end
  
  def css_image(*styles)
    "img #{styles.map {|s| "img-#{s}"}.join(' ')}"
  end

  def css_icon(name, spaces = 2)
    content_tag :i, ('&nbsp;' * spaces).html_safe, class: "fa fa-#{name}"
  end
  
  def css(options = {})
    output = []
    options.each do |k, v|
      case k
      when :button
        output << css_button(*v)
      when :align
        output << css_align(v)
      end
    end
    
    output.join(' ')
  end
  
  def css_form_control
    "form-control"
  end

  def json_settings_form_value(object)
    case object
    when TrueClass, FalseClass
      html = hidden_field_tag(:type, 'boolean')
      html << (content_tag :div, class: "radio-inline" do
        label_tag :value_1 do 
          radio_button_tag(:value, "1",  object == true) + " true"
        end
      end)

      html << (content_tag :div, class: "radio-inline" do
        label_tag :value_0 do 
          radio_button_tag(:value, "0", object == false) + " false"
        end
      end)
    when Numeric
      html = hidden_field_tag(:type, 'numeric')
      html << (content_tag :div, class: "form-group" do
        label_tag(:value, "Value") + number_field_tag(:value, object, class: 'form-control')
      end)

    when Array
      html = hidden_field_tag(:type, 'array')
      html << (content_tag :div, class: "form-group" do
        label_tag(:value, "Value") + text_area_tag(:value, object.join(', '), class: 'form-control')
      end)
    else 
      html = hidden_field_tag(:type, 'text')
      html << (content_tag :div, class: "form-group" do
        if object && object.size > 60
          label_tag(:value, "Value") + text_area_tag(:value, object, class: 'form-control', rows: 8)
        else
          label_tag(:value, "Value") + text_field_tag(:value, object, class: 'form-control')
        end
      end)
    end

    html.html_safe
  end

  def json_settings_tree(url, parent, object, s, path, depth, addable_to_levels = [])
    case object
    when TrueClass, FalseClass, Numeric, Array, String, NilClass
      s << "<code>#{object}</code>&nbsp;&nbsp;&nbsp;"
      s << link(:setting, :edit, '#', :class => 'btn btn-default btn-xs btn-edit-setting', :data => { 
        form: render(:partial => '/application/settings/setting_form', :locals => {
          object: object, value: object, :key => path.last,
          :url => url.sub('_key_', path.take(depth-2).join(':')), :op => :edit,
          :title => "Edit a setting", :path => path.join('/')
        }).gsub("\n", "")
      })

      if addable_to_levels.include?(depth - 2)
        s << '&nbsp;'
        s << link(:setting, :destroy, url.sub('_key_', path.join(':')), method: :delete, confirm: true, 
          class: 'btn btn-danger btn-xs btn-delete-setting')
      end
    when Hash
      s << '<ul dir="ltr">'
      
      object.each do |k, v|
        path << k
        s << "<li><strong>#{k.titleize}</strong>: "
        if addable_to_levels.include?(depth) and v.kind_of?(Hash)
          s << link(:setting, :new, '#', :class => 'btn btn-success btn-xs btn-add-setting', :data => { 
            form: render(:partial => '/application/settings/setting_form', :locals => {
              object: v, :key => '', :value => '', :title => "Add a setting", 
              type: v.first.kind_of?(Array) ? v.first.second : v,
              :url => url.sub('_key_', path.join(':')), :op => :add, :path => path.join('/')
            }).gsub("\n", "")
          })
        end

        json_settings_tree(url, object, v, s, path, depth + 1, addable_to_levels)
        s << '</li>'
        path.pop
      end

      s << '</ul>'
    end
  end
  
  def logo_path
    path = "/images/logo/%{dark_or_light}-%{flavor}.%{locale}.png"
    dark_or_light = :light
    flavor = current_account.config['theme']['flavor'] || $site['theme']['flavor']
    path % {dark_or_light: dark_or_light, flavor: flavor , locale: locale}
  end

  def ui_klass_labels(klass)
    labels = ''.html_safe #content_tag :span, klass.tuition.to_s, :class => "label label-klass"
    unless klass.course.country.blank? 
      flag = flag_tag(klass.course.country)
      labels << content_tag(:span, flag, :class => "text-muted") 
      labels << "&nbsp;".html_safe
    end

    t('config.level').each_with_index do |l, i|
      if Course.tagged_with(l.first, :on => :levels).to_a.include? klass.course
        (0..i).each { labels << content_tag(:i, '', class: 'fa fa-circle') }
        ((i+1)..3).each { labels << content_tag(:i, '', class: 'fa fa-circle-o') }
        labels << content_tag(:span, l.second, :class => "text-muted") 
        labels << ("&nbsp;".html_safe)
      end
    end
    
    labels.html_safe
  end
  
  def ui_image_src(url_1, url_2 = '/images/nobody-th.png')
    return url_1 unless url_1.blank?
    url_2
  end
  
  def ui_options_button_text
    content_tag(:i, '&nbsp;&nbsp;'.html_safe + t('page.titles.actions'), :class => 'fa fa-cog')
  end
  
  def ui_nav_pills(items, options = {})
    content_tag :ul,  :class => "nav nav-pills #{options[:class]}" do
      html = ''
      items.each do |item|
        case item
        when String
          html << content_tag(:li, item)
        when Array
          html << content_tag(:li, item[0], :class => item[1] ? 'active' : nil )
        end
      end
      
      html.html_safe
    end
  end
  
  def ui_panel(header, action, body, table = nil, style = 'default')
    content_tag :div, class: "panel panel-#{style}" do
      html = ''
      
      if header.present? or action.present?
        html << content_tag(:div, "#{header} #{action}".html_safe, class: "panel-heading")
      end
      
      html << ( content_tag :div, class: "panel-body" do
        if body.present?
          case body
          when Array
            content_tag :ul do
              items = ''
              body.each_with_index do |link, ndx|
                if link.is_a?(Array)
                  items << content_tag(:li, "#{link[0]} #{link[1]}".html_safe)
                else
                  items << content_tag(:li, link)
                end
              end
            
              items.html_safe
            end
          else
            body
          end
        else
          t('page.text.no_record_found')
        end
      end ) if body.present?
      
      html << table if table.present?
      
      html.html_safe
    end
  end
  
  def ui_header(text, options = {})
    options[:style] ||= :h3
    
    content_tag :div, class: "page-header" do
      html = ''
      html << options[:action] if options[:action].present?
      html << ( content_tag options[:style] do
        hdr = text
        if hdr
          if options[:subtext].present?
            hdr << tag(:br)
            hdr << content_tag(:small, options[:subtext])
          end
        
          hdr.html_safe
        end
      end )
      
      html.html_safe
    end 
  end
  
  def staff_or_student_view(default_action = nil)
    if @course and !@course.id.nil? and staff?(current_user, @course)
      klass = (@klass || @course.klasses.last)
      if klass and !klass.new_record?
        link :klass, :show, learn_klass_path(klass), as: :student_view, :class => 'btn btn-default pull-right'
      end
    elsif @klass and staff?(current_user, @klass.course)
      link :klass, :show, teach_course_klass_path(@klass.course, @klass), as: :instructor_view, :class => 'btn btn-default pull-right'
    elsif default_action.present?
      default_action
    end
  end
  
  def ui_alert (header, body, style = :success, dismissable = true)
    content_tag :div, class: "alert alert-#{style} #{'alert-dismissable' if dismissable}" do
      html = ''
      if dismissable
        html << content_tag(:button, '&times;'.html_safe, type: "button", class: "close", :'data-dismiss' => "alert")
      end
      
      html << content_tag(:strong, header) if header
      html << body
      
      html.html_safe
    end
  end
  
  def ui_media(media, heading, body, options = {kind: :div, align: :left})
    options[:kind] ||= :div
    options[:align] ||= :left
    options[:img_options] ||= {}
    
    content_tag options[:kind], class: "media", :id => options[:id] do
      html = ''
      html << ( content_tag :a , class: "pull-#{options[:align]}", href: "#" do
        if options[:video]
          ui_video(media, nil, thumbnail: true, :class => 'media-object img-polaroid pull-left')
        else
          tag :img, { class: "media-object", src: "#{media}", alt: "#{options[:alt]}" }.merge(options[:img_options])
        end
      end )
      
      html << ( content_tag :div, class: "media-body" do
        main = (content_tag :h4, class: "media-heading" do
          (options[:subhdr].present? ? (heading + content_tag(:small, options[:subhdr])) : heading).html_safe
        end )
        main << body
        
        main.html_safe
      end )
      
      html.html_safe
    end
  end
  
  def ui_modal(body, options = {})
    html = ''
    html << ( content_tag :div, class: "modal-header" do
      content_tag(:button, '&times;'.html_safe, type: "button", class: "close", :'data-dismiss' => "modal") +
      content_tag(:h4, options[:header], id: "page-modal-label", class: "modal-title")
    end ) if options[:header].present?
    
    html << content_tag(:div , body, class: "modal-body")

    html << ( content_tag :div, class: "modal-footer" do
      content_tag(:button, t('activerecord.actions.close'), type: "button", class: "btn btn-default", :'data-dismiss' => "modal") +
      content_tag(:button, options[:action], type: "button", class: "btn btn-primary")
    end ) if options[:action].present?
    
    options[:wrapper] ||= false
    unless options[:wrapper]
      html.html_safe
    else
      content_tag :div, id: options[:wrapper], class: "modal fade" do
        content_tag :div, class: "modal-dialog" do
          content_tag :div, class: "modal-content" do
            html.html_safe
          end
        end
      end
    end
  end
  
	def ui_dropdown(name, links, options = {})
    wrapper = options[:wrapper] || :li
    options = options.reject { |k,v| k == :wrapper }
    options[:class] = "dropdown #{options[:class]}"
    content_tag wrapper, options  do 
      html = ''
      html << ( content_tag :a , href: "#", class: "dropdown-toggle", :'data-toggle' => "dropdown" do
        (name + ' ' + content_tag(:b, '', :class => 'caret')).html_safe
      end )
     
      html << ( content_tag :ul, class: "dropdown-menu" do
        list = ''
    		links.each do |link|
    			if link.nil?
    				list << content_tag(:li, '', class: "divider")
          else
            list << content_tag(:li, link)
          end
    		end
        
        list.html_safe
      end )
      
      html.html_safe
    end
	end
  
  def ui_button_dropdown(name, links, options = {})
    content_tag :div, :class => "btn-group #{options[:dropdown_class]} #{css_align(options[:align]) if options[:align]}" do 
      html = ''
      html << ( content_tag :button , type: "button", class: "dropdown-toggle #{options[:class]}", :'data-toggle' => "dropdown" do
        (name + ' ' + content_tag(:b, '', :class => 'caret')).html_safe
      end )
 
      html << ( content_tag :ul, class: "dropdown-menu" do
        list = ''
    		links.each do |link|
    			if link.nil?
    				list << content_tag(:li, '', class: "divider")
          else
            list << content_tag(:li, link)
          end
    		end
    
        list.html_safe
      end )
  
      html.html_safe
    end    
  end
  
  def true?(val)
    !val.nil? && val == true
  end
  
  def false?(val)
    !val.nil? && val == false
  end
  
  def form_help
    render :partial => "/ui_form_help"
  end
  
  # Forms  
  def themed_form_for(record, options = {}, &block)
    form_for(record, options, &block)
  end
  
  def form_header(options = {})
    key = case action_name
    when 'new', 'create'
      "new"
    when 'edit', 'update'
      "edit"
    else
      action_name
    end 

    name = (options[:name] || t("activerecord.models.#{options[:model] || controller_name.classify.downcase}.one"))
    header = t(key, scope: 'activerecord.actions', name: name )

    options[:wrapper] = true if options[:wrapper].nil?
    style = (options[:style] || :h3)
    unless options[:wrapper]
      content_tag style, header.html_safe
    else
      content_tag :div, class: "page-header" do
        content_tag style, header.html_safe
      end
    end
  end
  
  def form_input_wrapper(form, field, input, label = true, hint = false)
    has_error = form.object.respond_to?(:errors) && form.object.errors[field].present? 
    content_tag :div, class: "form-group #{"has-error" if has_error}" do
      validators = form.object.class.respond_to?(:validators_on) ? form.object.class.validators_on(field).map(&:class) : nil
      if validators && (validators.include?(ActiveRecord::Validations::PresenceValidator) || 
         validators.include?(ActiveModel::Validations::PresenceValidator))
        style_class = "control-label required"
      else
        style_class = "control-label"
      end
      
      html = case label
      when TrueClass
        form.label(field, class: style_class)
      when FalseClass
        ''
      else
        form.label(field, label, class: style_class)
      end

      html << ' '
      html << input
      if has_error
        html << ( content_tag :span, form.object.errors[field].join(' '), class: "help-block" )
      elsif hint
        case hint
        when TrueClass
          hint = t("activerecord.hints.#{form.object.class.name.underscore}.#{field}", 
            :default => t("activerecord.hints.#{field}"))
        end

        html << ( content_tag :span, hint, class: "help-block") if hint
      end
        
      html.html_safe
    end
  end
 
  def augmented_options(form, field, options)
    to = { class: "form-control" }
    to.each do |k, v|
      options[k] = options[k].present? ? "#{options[k]} #{v}" : v
    end
    
    placeholder = true?(options[:placeholder])
    if placeholder
      options[:placeholder] = t("activerecord.placeholders.#{form.object.class.name.underscore}.#{field}", 
        :default => t("activerecord.placeholders.#{field}"))
    end
    
    options
  end
  
  def cleaned_options!(options)
    hint = options.include?(:hint) ? options[:hint] : false
    #hint = options.include?(:hint) && options[:hint] == true ? true : false
    #label = options.include?(:label) && options[:label] == false ? false : true
    label = options.include?(:label) ? (options[:label] == false ? false : options[:label]) : true
    options.reject!{|k,v| %(hint label).include? k.to_s}
    
    return label, hint
  end
  
  def form_text(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.text_field(field, augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_text_area(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.text_area(field, augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_static(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    value = options[:value] || form.object[field]
    input = content_tag(:p, value, class: "form-control-static")
    form_input_wrapper(form, field, input, label, hint) 
  end

  def form_code(form, field, options = {}) 
    value = options[:value]
    lang = options[:lang]
    updated_field = options[:field]
    label, hint = cleaned_options!(options)

    input = highlighted_code value, lang, updated_field
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_markdown(form, model, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = markdown_textarea(form, model, field, augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint)
  end 
  
  def form_password(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.password_field(field, augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_hidden(form, field, options = {}) 
    form.hidden_field(field,  augmented_options(form, field, options))
  end
  
  def form_email(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.email_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint)
  end
  
  def form_search(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.search_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint)
  end
  
  def form_number(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.number_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint)
  end
  
  def form_url(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.url_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint)
  end
  
  def form_range(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.range_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint)
  end
  
  def form_telephone(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.telephone_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_phone(form, field, options = {}) 
    form_telephone(form, field, options) 
  end
  
  def form_date(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.date_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_time(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.time_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_datetime(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.datetime_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_datetime_local(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.datetime_local_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_month(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.month_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_week(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.week_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end

  def form_color(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.color_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_file(form, field, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.file_field(field,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_checkbox(form, field, options = {}, checked_value = "1", unchecked_value = "0")
    label, hint = cleaned_options!(options)
    text = case label
    when TrueClass
      t("activerecord.attributes.#{form.object.class.name.underscore}.#{field}")
    when FalseClass
      ''
    else
      label
    end
    input = form.label field do
      form.check_box(field, options) + " #{text}"
    end
    
    form_input_wrapper(form, field, input, false, hint)
  end
  
  def form_checkbox_collection(form, field, collection, value, text, options = {}, html_options = {})
    label, hint = cleaned_options!(options)
    input = ( form.collection_check_boxes field, collection, value, text, options, html_options do |b|
      content_tag :div, :class => :checkbox do 
        b.label { b.check_box(checked: b.value.in?(form.object.tags)) + b.text }
      end
    end )
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_radio_button(form, field, tag, options = {}) 
    label, hint = cleaned_options!(options)
    input = form.radio_button(field, tag,  augmented_options(form, field, options))
    form_input_wrapper(form, field, input, label, hint) 
  end
  
  def form_select(form, field, collection, options = {include_blank: true}, html_options = {}) 
    label, hint = cleaned_options!(options)
    value = options[:value].present? ? options[:value] : (
      form.object.respond_to?(:[]) ? form.object[field] : nil)
      
    case collection
    when Hash
      select_options = options_for_select(collection, value)
    else
      if collection.kind_of? Array and (
          collection.first.kind_of? Symbol or 
          collection.first.kind_of? String or
          collection.first.kind_of? Fixnum
         )
         
        select_options = options_for_select(collection, value)
      else
        value_method = :id
        text_method = :name

        select_options = options_from_collection_for_select(collection, value_method, text_method, value)
      end
    end 

    options = options.delete_if {|k,v| %w(value).include? 'k' }
    input = form.select(field, select_options, options, augmented_options(form, field, html_options))
    form_input_wrapper(form, field, input, label, hint)
  end
  
  def form_time_zone(form, field, options = {}, html_options = {}) 
    label, hint = cleaned_options!(options)
    input = form.time_zone_select(field, ActiveSupport::TimeZone.all.sort, 
      options, augmented_options(form, field, html_options)) 
    form_input_wrapper(form, field, input, label, hint)
  end
  
  def form_country_select(form, field, options = {iso_codes: true}, html_options = {}) 
    label, hint = cleaned_options!(options)
    options[:iso_codes] = true
    input = form.country_select(field, nil, options, augmented_options(form, field, html_options)) 
    form_input_wrapper(form, field, input, label, hint)
  end
  
  def form_submit(form, cancel = nil, links = [], options = {})
    content_tag :div, class: "form-group" do
      key = options[:as] || case action_name
      when 'new', 'create'
        case controller_name
        when 'sessions'
          'sign_in'
        when 'registrations'
          'sign_up'
        when 'attempts'
          'submit'
        else
          "create"
        end
      when 'edit', 'update'
        "update"
      else
        "submit"
      end 
      
      confirm = nil
      if options.present? and options[:data].present? 
        confirm = options[:data][:confirm]
        title = options[:data][:"confirm-title"]
      end
      
      html = ''
      name = (options[:name] || t("activerecord.models.#{options[:model] || controller_name.classify.downcase}.one"))
      if confirm.present?
        html << %(
        <div id="form-modal" class="modal fade" role="dialog" aria-labelledby="page-modal-label" aria-hidden="true">
          <div class="modal-dialog modal-md">
            <div class="modal-content"></div>
          </div>
        </div>
        )
        link = content_tag(:button, name, type: "submit", class: options[:class])
        html << link_to(name, '#', :class => options[:class],
                  :onclick => "ui_modal_confirmation('form', '#{options[:data][:"confirm-title"] || t('page.titles.hold_on')}', '#{confirm}', '#{j link}', '#{t('activerecord.actions.close')}' )")
      else
        if options[:image]
          html << ( content_tag :button, type: "submit", style: "border: none; background: none;" do
            options[:image]
          end )
        else
          html << content_tag(:button, t(key, scope: "activerecord.actions", name: name), 
              type: "submit", class: "btn btn-primary")
        end
      end
      
      html << " "
      if cancel.present?
        if cancel == true
          html << link_to(t("activerecord.actions.cancel"), _back_url, class: "btn btn-default")
        else
          html << link_to(t("activerecord.actions.cancel"), cancel, class: "btn btn-default")
        end
      end
      
      links.each do |link|
        html << " "
        if link[:path].present?
          html << (link_to link[:text], link[:path])
        else
          html << link[:text]
        end
      end
      
      html.html_safe
    end
  end
end