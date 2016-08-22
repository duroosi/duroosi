module UsersHelper
  def user_menu
    return unless current_user
    
    add_to_app_menu :user, link: link(:user, :change_password, main_app.edit_auth_registration_path(current_user)), active: controller_name == 'registrations' && action_name.in?(['edit', 'update'])
    add_to_app_menu :user, link: link(:profile, :edit_profile, main_app.edit_user_path(current_user)), active: controller_name == 'users' && action_name.in?(['edit', 'update'])
    
    if current_user.has_role?(:blogger) && !current_user.has_role?(:admin) 
      add_to_app_menu :user, link: link(:page, :blog_posts, main_app.pages_path), active: controller_name == 'pages'
    end

    if current_account.config['allow_user_student_dependents']
      add_to_app_menu :user, link: link(:student, :index,  main_app.learn_students_path), active: controller_name == 'students' && action_name == 'index'
    end

    if current_account.config['allow_faculty_applications']
      if !current_user.has_role?(:admin) && !current_user.has_role?(:faculty)
        section = :teaching
        faculty_application = FacultyApplication.approved_or_pending(current_user).first
        if faculty_application 
          if faculty_application.pending?
            add_to_app_menu(:user, {link: link(:faculty_application, :become_a_faculty, main_app.edit_faculty_application_path(faculty_application)), active: controller_name == 'faculty_applications' && action_name.in?(['new', 'create'])}, section)
          end
        else
          add_to_app_menu(:user, {link: link(:faculty_application, :become_a_faculty, main_app.new_faculty_application_path), active: controller_name == 'faculty_applications' && action_name.in?(['new', 'create'])}, section)
        end
      end
    end
    
    if current_user.has_role?(:admin) || current_user.has_role?(:faculty)
      add_to_app_menu(:user, {link: link(:course, :index, main_app.teach_courses_path), active: controller_name == 'courses' && action_name.in?(['index'])}, :teaching)
      add_to_app_menu(:user, {link: link(:course, :start_new_course, main_app.new_teach_course_path), active: controller_name == 'courses' && action_name.in?(['new', 'create'])}, :teaching)
    end
    
    add_to_app_menu(:user, [
      {link: link_to(t('page.title.available_klasses'), main_app.learn_klasses_path), active: controller_name == 'klasses' && params[:s].nil?},
      {link: link_to(t('page.title.taking_klasses'), main_app.learn_klasses_path(:s => :taking)), active: controller_name == 'klasses' && params[:s] == 'taking'},
      {link: link_to(t('page.title.enrolled_klasses'), main_app.learn_klasses_path(:s => :enrolled)), active: controller_name == 'klasses' && params[:s] == 'enrolled'},
      {link: link_to(t('page.title.taken_klasses'), main_app.learn_klasses_path(:s => :taken)), active: controller_name == 'klasses' && params[:s] == 'taken'}], :learning)
    
    if current_user.has_role? :admin
      section = :administration

      add_to_app_menu(:user, {link: link_to(t('page.title.dashboard'), admin_dashboard_path), active: controller_name == 'dashboard'}, section)

      if current_user.id == 1
        add_to_app_menu(:user, {link: link(:account, :index,  main_app.admin_accounts_path), active: controller_name == 'accounts'}, section)
        # if Rails.application.secrets.redis_enabled
        #   add_to_app_menu(:user, link_to(:Sidekiq, main_app.sidekiq_web_path, target: '_new'), section)
        # end
      end

      add_to_app_menu(:user, [
        {link: link(:user, :index, main_app.users_path), active: controller_name == 'users' && action_name != 'home'}, 
        {link: link(:page, :index, main_app.pages_path), active: controller_name == 'pages' && action_name == 'index'}, 
        {link: link(:medium, :index, main_app.media_path), active: controller_name == 'media'}, 
        {link: link(:announcement, :index,  main_app.admin_announcements_path), active: controller_name == 'announcements'}], section)

      section = :settings
      if current_user.id == 1
        add_to_app_menu(:user, {link: link(:configuration, :site_settings,  main_app.admin_config_edit_path), active: controller_name == 'config' && action_name == 'edit'}, section)
      end
      if current_user.id == current_account.user_id
        add_to_app_menu(:user, {link: link(:account, :account_settings,  main_app.edit_admin_account_path(current_account)), active: controller_name == 'accounts' && action_name.in?(['edit', 'update'])}, section)
      end

      if Rails.application.secrets.redis_enabled
        add_to_app_menu(:user, {link: link(:translation, :index,  main_app.edit_admin_translation_path(I18n.locale)), active: controller_name == 'translations' && action_name == 'edit'}, section)
      end
    end

    mountable_fragments :user_menu
  end
end
