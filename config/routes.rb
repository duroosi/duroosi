Rails.application.routes.draw do
  devise_for :users, :controllers => {
    :registrations => "user/registrations" ,
    :omniauth_callbacks => "omniauth_callbacks" 
  }
  
  # Concerns
  concern :sortable do
    post :sort, :on => :collection
  end
  
  concern :with_media do
    resources :media
  end
  concerns :with_media
  
  concern :with_materials do
    resources :materials, :only => [:show, :new, :create, :destroy]
  end
  
  concern :with_pages do
    resources :pages, :except => [:index]
  end
  
  concern :assessable do
    resources :questions, :except => :show do
      post :sort_option, :on => :member
    end
    resources :assessments, :except => :index do
      resources :q_selectors, :except => [:show, :index]
      get :preview, :on => :member
      post :sort_q_selector, :on => :member
    end
  end
  
  concern :announceable do
    resources :updates, :except => [:show]
  end
  
  resources :users do
    resources :access_tokens, :only => [:create, :destroy], :module => 'admin' do
      get :revoke, :on => :member
    end
  end
  
  resources :pages
  get 'blogs', :to => 'pages#blogs', :as => 'blogs'
  get 'pages/localized/:slug', :to => 'pages#localized', :as => 'localized_page'
    
	# Courses Resources
  namespace :teach do
  	resources :courses, concerns: [:with_media, :with_materials, :assessable, :with_pages] do
      #resources :settings, :only => [:index, :update]
	    resources :instructors, :except => [:show, :index], concerns: [ :sortable ]
  	  resources :units, concerns: [:sortable, :with_materials, :assessable, :with_pages] do
  	    resources :lectures, :except => :index, concerns: [:sortable, :with_materials, :assessable, :with_pages] do
          put :discuss, :on => :member
        end
      end
    
      resources :klasses do
        resources :forums, :except => :show do
          resources :topics 
        end
      
        resources :updates, :except => [:index, :show] do
          put :make, :on => :member
        end
        
        get :invite, :on => :member
        post :invite, :on => :member
        put :approve, :on => :member
        put :discuss, :on => :member
        
        get 'students/:student_id/records', :to => 'klasses#records', :as => 'student_records'
      end
      
      get :settings, :on => :member
      post :configure, :on => :member
      delete :configure, :on => :member
    end
  end
  
  # Klasses Resources
  namespace :learn do
    resources :students 
    
    resources :klasses, :only => [:index, :show] do
      resources :instructors, :only => :index
      resources :lectures, :only => [:index, :show] do
        member do
          get :assessments, :as => :show_assessments_of, :to => 'lectures#show_assessments'
          get :comments, :as => :show_comments_of, :to => 'lectures#show_comments'
          get 'pages/:page_id', :as => :show_page_of, :to => 'lectures#show_page'
          get 'materials/:material_id', :as => :show_material_of, :to => 'lectures#show_material'
        end
      end
      
      resources :units, :only => [] do
        resources :pages, :only => :index
        resources :materials, :only => :index
      end
      
      resources :pages, :only => [ :show, :index ]
      resources :materials, :only => :index
      resources :updates, :except => [ :show, :index ]
      get :access, :on => :member
      get :report, :on => :member
      get :students, :on => :member
      
      resources :forums do
        resources :topics, :except => :index do
          resources :posts, :except => [:index, :show] do
            resources :posts
            
            put :up, :on => :member
            put :down, :on => :member
          end
          
          put :up, :on => :member
          put :down, :on => :member
        end
      end
    
      resources :assessments, :only => [:index, :show] do
        resources :attempts, :only => [:new, :create] do
          post :show_answer, :on => :member
        end
      
        post 'questions/:question_id/show_answer',
          :to => 'attempts#show_answer',
          :as => 'show_answer'
      end
    
      put 'accept', :to => 'klasses#accept', :on => :member
      put 'decline', :to => 'klasses#decline', :on => :member
      
    	put 'drop', :to => 'klasses#drop', :on => :member
      post 'enroll', :to => 'klasses#enroll', :on => :member
      put 'students/:id/current', :to => 'students#current',
        :as => 'current_student'
    end
    
    get 'search/klasses', :to => 'klasses#search', :as => 'klass_search'
  end
  
  # Mountable engines
  Rails.application.config.site_engines.each do |name, engine|
    mount engine[:class] => "/#{name}"
  end
    
  namespace :admin do
    resources :announcements, :except => :show do
      get :hide, :on => :member
    end

    resources :accounts do
      post :configure, :on => :member
    end
    
    resources :users, :only => [:new, :create]
  end
  
  get 'admin/config/edit', :to => 'admin/config#edit'
  post 'admin/config', :to => 'admin/config#update'
  
  get 'admin/translation/:locale/edit', :to => 'admin/translations#edit', :as => :edit_admin_translation  
  post 'admin/translation/:locale', :to => 'admin/translations#update', :as => :admin_translation
  delete 'admin/translation/:locale', :to => 'admin/translations#update'

  post "miscellaneous/contactus"
    
  # Top-level pages
  get 'about', :to => "miscellaneous#team", :as => 'about'
  get 'contactus', :to => "miscellaneous#contactus", :as => 'contactus'
  get 'home', :to => 'users#home', :as => :home
  root :to => 'users#front', :via => :get  

  # Statistics Paths
  get 'statistics', :to => 'statistics#all', :as => :statistics
  get 'statistics/courses', :to => 'statistics#course', :as => :course_statistics
  get 'statistics/klasses/:klass_id', :to => 'statistics#klass', :as => :klass_statistics
  
	# Temporary fix for catching routing errors
	get '*path', :to => 'application#routing_error'
end