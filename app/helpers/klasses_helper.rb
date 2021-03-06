module KlassesHelper  
  def enrolled_or_staff?
    @enrolled_or_staff ||= (@klass.present? && (@klass.enrolled?(current_student) || staff?(current_user, @klass.course)))
  end
  
  def klass_actions(klass, in_preview = false, right = false)
    links = []
    align = right ? :right : nil
    if klass.enrolled?(current_student) || klass.previously_enrolled?(current_student)
      #go2class or #go2class_past
      links << link(:klass, :open, main_app.learn_klass_path(klass), :class => "ui primary button")
    elsif klass.can_enroll?(current_user, current_student)
      if (controller_name == 'klasses' && action_name == 'show') ||
         (controller_name == 'lectures' && action_name == 'index') || @lecture
        # Enrollment links
        if klass.dropped?(current_student)
          #enroll again
          links << (capture do
            content_tag(:p, t('page.text.free_to_enroll_again')) +
            link(:enrollment, :enroll, main_app.enroll_learn_klass_path(klass), remote: user_signed_in?, :class => "ui primary button")
          end)
        elsif !klass.private || klass.invited_and_not_yet_accepted?(current_user)
          if !in_preview && klass.previewed
            #preview
            links << (capture do
              content_tag(:p, t('page.text.free_to_preview')) +
              link(:enrollment, :open,  main_app.learn_klass_lectures_path(klass),
                  :class => "ui primary button")
            end)
          else
            #enroll
            links << (capture do
              (!in_preview ? content_tag(:p, t('page.text.free_to_enroll')) : ''.html_safe) +
              link(:enrollment, :enroll, main_app.enroll_learn_klass_path(klass), remote: user_signed_in?, 
                :class => "ui primary button")
            end)
          end
        end

        mountable_fragments(:klass_enrollment_actions, klass: klass, action: :enroll, previewed: in_preview, links: links, right: right)

        if klass.invited_and_not_yet_accepted?(current_user)
          #decline
          links << link(:enrollment, :decline, main_app.decline_learn_klass_path(klass),
                      :class => "ui negative button", :method => :put)
        end

        # if !in_preview && klass.previewed
        #   #preview
        #   links << link(:enrollment, :preview,  main_app.learn_klass_lectures_path(klass),
        #       :class => "ui button")
        # end
      else
        #learn_more
        links << link(:klass, :learn_more, learn_klass_path(klass), :class => "ui primary button")
        mountable_fragments(:klass_flags_actions, klass: klass, previewed: in_preview, links: links, right: right)
      end
    elsif current_user && staff?(current_user, klass)
      #admin or faculty
      links << link(:klass, :open, main_app.teach_course_klass_path(klass.course, klass), :class => "ui primary button")
    end

    links.join(' ').html_safe
  end

  def ui_klass_enrollment_action(klass, action, previewed = false, right = false)
    if action == :enroll
      klass_actions(klass, previewed, right)
    else
      link(:klass, :drop, main_app.drop_learn_klass_path(@klass), method: :put, confirm: true, class: 'ui negative button')
    end
  end

  def klass_availability(klass)
    days = (Date.current - klass.begins_on).to_i
    starts_in = if days == 0
      t('page.text.today')
    elsif days < 0
      t('page.text.in_days', :count =>  -1 * days)
    elsif days > 0
      past = klass.ends_on ? (Date.current - klass.ends_on) : nil
      if past == nil || past <= 0
        t('page.text.open_for_enrollment')
      else
        t('page.text.closed')
      end
    end
  end
  
  def forum_breadcrumbs(item)
    items = []
    case item
    when Topic
      items << {name: item.name, link: nil}
      items << {name: item.forum.name, link: learn_klass_forum_path(@klass, item.forum), remote: true}
      items << {name: Forum.model_name.human(count: 3), link: learn_klass_forums_path(@klass)}
    when Forum
      items << {name: item.name, link: nil}
      items << {name: Forum.model_name.human(count: 3), link: learn_klass_forums_path(@klass)}
    end
    
    unless items.empty?
      content_tag :div, class: 'ui breadcrumb' do
        crumbs = items.reverse.map{|i| i[:link] ? link_to(i[:name], i[:link], remote: i[:remote], class: 'section') : content_tag(:div, i[:name], class: 'active section')}
        crumbs.join(ui_icon('right angle icon divider')).html_safe
      end
    end
  end
  
  def render_content(item, answer = nil, result = nil)
    title = ''
    body = ''
    if item.kind_of?(Material)
      title = item.medium.name
      body = if item.kind == 'video' || item.of_content_type?('video/')
        ui_video item, nil, :autoplay => true
      elsif item.kind == 'audio' || item.of_content_type?('audio/')
        ui_audio item, :autoplay => true
      elsif item.kind =='image' || item.of_content_type?('image/')
        image_tag item.at_url
      else
        ui_document_viewer item.at_url
      end 
    elsif item.kind_of?(Page) 
      title = item.name
      body = markdown(item.about, :html => item.html) 
    elsif item.kind_of?(Question) 
      if answer.nil?
        activity = item.activity('attempted', @klass, current_student)
        answer = activity ? activity.data : nil
      end

      title = Question.model_name.human
      body = render partial: "learn/questions/show", locals: { question: item, answer: answer, result: result}
    elsif item.kind_of?(Assessment)
      title = item.name
      body = render partial: "learn/assessments/assessment", locals: { assessment: item } 
    end
    
    return title, body
  end
end
