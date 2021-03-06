module Mediable
  extend ActiveSupport::Concern

  included do
    before_action :set_medium, only: [:show, :edit, :update, :destroy]
    helper_method :the_path_out, :the_form_path, :the_material_path_out
    responders :modal, :flash, :http_cache
    
    def index
      if params[:m]
        @material = Material.new(:kind => params[:s])
        @req_objects << @material
      end

      kind = params[:s] ? params[:s] : 'video'
      if @course
        @q = @course.media.where(:kind => kind).order('created_at desc').search(params[:q])
      else
        @q = Medium.scoped.where(:course_id => nil, :kind => kind).order('created_at desc').search(params[:q])
      end

      @media =  @q.result.page(params[:page]).per(10)

      respond_with @media do |format|
        format.html { render 'application/media/index' }
        format.js { render 'application/media/index' }
      end
    end

    def show
      respond_with @medium do |format|
        format.html {redirect_to @medium.at_url}
        format.js {render 'application/media/show'}
      end
    end

    def new
      attributes = { :kind => params[:s], :m => params[:m] }
      @medium = @course ? @course.media.new(attributes) : Medium.new(attributes)
      @medium.is_a_link = true#params[:m] ? false : true
      respond_with @medium do |format|
        @form = 'application/media/form'
        format.js {render 'new'}
      end
    end

    def multi
      @medium = @course ? @course.media.new : Medium.new
      @medium.is_a_link = false
      respond_with @medium do |format|
        format.html {render 'application/media/multi'}
      end
    end

    def edit
      @medium.is_a_link = @medium.path.blank?
      if @medium.is_a_link
        @medium.source = @medium.content_type == "link/youtube" ? 'youtube' : 'www'
      end

      respond_with @medium do |format|
        format.js {render 'application/media/edit'}
      end
    end

    def update
      @medium.is_a_link = @medium.path.blank?
      set_kind_and_extension(@medium, medium_params[:url], medium_params[:source])

      respond_with @medium do |format|
        if @medium.update(medium_params)
          format.js { render 'application/media/show' }
        else
          format.js { render 'application/media/edit' }
        end
      end
    end

    def set_kind_and_extension(medium, url, source)
      if medium.is_a_link
        ext = File.extname(url)
        if ext.present?
          ext = ext[1..-1]
          medium.kind = medium.kind_from_extension(ext) if ext.present?
        end

        if source != 'youtube' && ext.present? && $site['file_content_types'][ext].present?
          medium.content_type = "link/#{$site['file_content_types'][ext]}"
        else
          medium.content_type = "link/#{source}"
        end
      else
        ext = medium.path.file.extension
        medium.kind = medium.kind_from_extension(ext) if ext.present?
      end
    end

    def create
      @medium = @course ? @course.media.new(medium_params) : Medium.new(medium_params)
      set_kind_and_extension(@medium, medium_params[:url], medium_params[:source])

      respond_with @medium do |format|
        @form = 'application/media/form'
        if @medium.save
          format.js {
            if @medium.m.present?
              path_ids = @medium.m.split(',')
              material_params = { :medium_id => @medium.id, :kind => @medium.kind, :tag_list => path_ids[3] != '0' ? path_ids[3] : nil }
              @unit = path_ids[1] != '0' ? @course.units.find(path_ids[1].to_i) : nil
              @lecture = path_ids[2] != '0' ? @unit.lectures.find(path_ids[2].to_i) : nil
              if @lecture
                @material = @lecture.materials.create(material_params)
              elsif @unit
                @material = @unit.materials.create(material_params)
              else
                @material = @course.materials.create(material_params)
              end
            end
            
            render 'reload'
          }
          format.json { head :ok }
        else
          format.js { render 'new' }
          format.json { head :ok }
        end
      end
    end

    def destroy
      @medium.destroy
      respond_with @medium do |format|
        format.html { redirect_to the_path_out(s: @medium.kind) }
      end
    end

    private
    def set_medium
      @medium = Medium.scoped.find(params[:id])
    end

    def the_form_path
      [@medium]
    end

    def the_path_out(params={})
      media_path(params)
    end

    def the_material_path_out(kind, m)
      path_ids = m.split(',')
      url_for :action => :new, :controller => 'teach/materials', :course_id => @course.id,
        :unit_id => path_ids[1] != '0' ? path_ids[1].to_i : nil,
        :lecture_id => path_ids[2] != '0' ? path_ids[2].to_i : nil,
        :s => kind, :t => path_ids[3] != '0' ? path_ids[3]: nil
    end

    def medium_params
      params.require(:medium).permit(:account_id, :course_id, :kind, :url, :path, :name, :is_a_link, :source,
        :caption, :copyrights, :m, :multi, :tag_list => [])
    end
  end

  module ClassMethods
	end
end
