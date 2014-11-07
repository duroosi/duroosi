module Teach
  class CoursesController < BaseController
    include WithSettings
    before_action :require_admin, :only => [:approve]
    responders :flash, :http_cache
    
    def index
      if current_user.has_role?(:admin)
        @q = Course.all.order('updated_at DESC').search(params[:q])
      else 
        @q = Course.for_user_with_roles(current_user, t('config.staff').keys).order('updated_at DESC').search(params[:q])
      end
      
      @courses = @q.result.page(params[:page]).per(10)
      respond_with :teach, @course
    end

    def show
      respond_with :teach, @course
    end

    def new
      @course = Course.new(:locale => I18n.default_locale)
      respond_with :teach, @course
    end
  
    def edit
      respond_with :teach, @course
    end

    def settings
      @course.settings = JSON.pretty_generate(@course.config)
      respond_with :teach, @course
    end
    
    def create
      @course = Course.new(course_params)
      @course.originator = current_user
      
      if @course.save
        current_user.add_role :instructor, @course
      end
      
      respond_with :teach, @course
    end

    def update
      @course.settings  = course_params['settings']
      if @course.settings.present?
        begin
          config = JSON.parse(@course.settings)
          $redis.set "config.course.#{current_account.slug}_#{@course.id}", config.to_json
          
          GradeDistribution.redistribute(@course, config)
        rescue JSON::ParserError
          @course.errors.add :settings, I18n.t('activerecord.messages.not_properly_formatted')
          render :action => :settings
          return
        end
      end
        
      @course.update(course_params)
      respond_with :teach, @course do |format|
        format.js { 
          @update_class = "crs_activate_#{@course.id}_link"
          render "courses" 
        }
      end
    end

    def configure
      do_configure(@course.config, "config.course.#{current_account.slug}_#{@course.id}", settings_teach_course_path(@course))
      GradeDistribution.redistribute(@course, @course.config)
    end

    def destroy
      @course.destroy
      respond_with :teach, @course
    end
  
    private 
    def course_params
      params.require(:course).permit(
        :slug, :name, :about, :active, :weeks, :workload, :locale, :country, :settings,
        :tag_list => [], :level_list => [], :major_list => [], :subject_list => [], 
        :school_list => []
      )
    end
  end
end