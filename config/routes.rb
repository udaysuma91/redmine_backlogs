def rb_match(object, path, hash)
  if Rails::VERSION::MAJOR < 3
    hash[:controller] = hash[:to].split('#')[0].to_sym
    hash[:action] = hash[:to].split('#')[1]
    hash.delete(:to)
    if hash[:via]
      hash[:conditions] = { :method => hash[:via] }
      hash.delete(:via)
    end
    object.connect path, hash
  elsif Rails::VERSION::MAJOR > 3
    if not hash[:via]
      hash[:via] = [:get]
    end
    match path, hash

  else # Rails 3
    match path, hash
  end
end

def rb_common_routes(rb)
  rb_match rb, 'releases/:project_id',
               :to => 'rb_releases#index', :via => [:get]
  rb_match rb, 'release/:project_id/new', :to => 'rb_releases#new', :via => [:get]
  rb_match rb, 'release/:project_id/new', :to => 'rb_releases#create', :via => [:post]
  rb_match rb, 'release/:release_id/shapshot',
               :to => 'rb_releases#snapshot', :via => [:get]

  rb_match rb, 'releases_multiview/:project_id/new',
               :to => 'rb_releases_multiview#new', :via => [:get, :post]
  rb_match rb, 'releases_multiview/:release_multiview_id',
               :to => 'rb_releases_multiview#show', :via => [:get]
  rb_match rb, 'releases_multiview/:release_multiview_id',
               :to => 'rb_releases_multiview#destroy', :via => [:delete]
  rb_match rb, 'releases_multiview/:release_multiview_id/edit',
               :to => 'rb_releases_multiview#edit', :via => [:get, :post]

  rb_match rb, 'updated_items/:project_id', :to => 'rb_updated_items#show', :via => [:get]
  rb_match rb, 'wikis/:sprint_id', :to => 'rb_wikis#show', :via => [:get]
  rb_match rb, 'wikis/:sprint_id/edit', :to => 'rb_wikis#edit', :via => [:get]
  rb_match rb, 'issues/backlog/product/:project_id',
               :to => 'rb_queries#show', :via => [:get]
  rb_match rb, 'issues/backlog/sprint/:sprint_id',
               :to => 'rb_queries#show', :via => [:get]
  rb_match rb, 'issues/impediments/sprint/:sprint_id',
               :to => 'rb_queries#impediments', :via => [:get]
  rb_match rb, 'statistics', :to => 'rb_all_projects#statistics', :via => [:get]

  rb_match rb, 'server_variables/sprint/:sprint_id.js',
              :to => 'rb_server_variables#sprint',
              :format => 'js', :via => [:get]
  rb_match rb, 'server_variables/sprint/:sprint_id.js',
              :to => 'rb_server_variables#sprint',
              :format => nil, :via => [:get]
  rb_match rb, 'server_variables.js',
              :to => 'rb_server_variables#index',
              :via => [:get],
              :format => 'js'
  rb_match rb, 'server_variables.js',
              :to => 'rb_server_variables#index',
              :format => nil, :via => [:get]
  rb_match rb, 'server_variables/project/:project_id.js',
              :to => 'rb_server_variables#project',
              :format => 'js', :via => [:get]
  rb_match rb, 'server_variables/project/:project_id.js',
              :to => 'rb_server_variables#project',
              :format => nil, :via => [:get]

  rb_match rb, 'master_backlog/:project_id',
               :to => 'rb_master_backlogs#show', :via => [:get]
  rb_match rb, 'master_backlog/:project_id/menu',
               :to => 'rb_master_backlogs#menu', :via => [:get]
  rb_match rb, 'master_backlog/:project_id/closed_sprints', :to => 'rb_master_backlogs#closed_sprints', :via => [:get]

  rb_match rb, 'impediment/create', :to => 'rb_impediments#create', :via => [:post]
  rb_match rb, 'impediment/update/:id', :to => 'rb_impediments#update', :via => [:post, :put]

  rb_match rb, 'epicboard/:project_id',
               :to => 'rb_epicboards#show', :via => [:get]
  rb_match rb, 'epic/create', :to => 'rb_epics#create', :via => [:post, :put]
  rb_match rb, 'epic/update/:id', :to => 'rb_epics#update', :via => [:post, :put]
  rb_match rb, 'epic/:id/tooltip', :to => 'rb_epics#tooltip', :via => [:get]

  rb_match rb, 'sprint/create', :to => 'rb_sprints#create', :via => [:post]
  rb_match rb, 'sprint/:sprint_id/update', :to => 'rb_sprints#update', :via => [:post, :put]
  rb_match rb, 'sprint/:sprint_id/close', :to => 'rb_sprints#close', :via => [:get, :post, :put]
  rb_match rb, 'sprint/:sprint_id/reset', :to => 'rb_sprints#reset', :via => [:post, :put, :get]
  rb_match rb, 'sprint/download/:sprint_id.xml', :to => 'rb_sprints#download', :format => 'xml', :via => [:get]
  rb_match rb, 'sprints/:project_id/close_completed', :to => 'rb_sprints#close_completed', :via => [:put]

  rb_match rb, 'sprints/:project_id', :to => 'rb_sprints_roadmap#index', :via => [:get]
  rb_match rb, 'sprints/:project_id/new', :to => 'rb_sprints_roadmap#new', :via => [:get]
  rb_match rb, 'sprints/:project_id/new', :to => 'rb_sprints_roadmap#create', :via => [:post]

  rb_match rb, 'stories/:project_id/:sprint_id.pdf', :to => 'rb_stories#index', :format => 'pdf', :via => [:get]
  rb_match rb, 'stories/:project_id.pdf', :to => 'rb_stories#index', :format => 'pdf', :via => [:get]
  rb_match rb, 'story/create', :to => 'rb_stories#create', :via => [:post, :put]
  rb_match rb, 'story/update/:id', :to => 'rb_stories#update', :via => [:post, :put]
  rb_match rb, 'story/:id/tooltip', :to => 'rb_stories#tooltip', :via => [:get]

  rb_match rb, 'calendar/:key/:project_id.ics', :to => 'rb_calendars#ical',
          :format => 'xml', :via => [:get]

  rb_match rb, 'burndown/:sprint_id',         :to => 'rb_burndown_charts#show', :via => [:get]
  rb_match rb, 'burndown/:sprint_id/embed',   :to => 'rb_burndown_charts#embedded', :via => [:get]
  rb_match rb, 'burndown/:sprint_id/print',   :to => 'rb_burndown_charts#print', :via => [:get]

  rb_match rb, 'hooks/sidebar/project/:project_id',
          :to => 'rb_hooks_render#view_issues_sidebar', :via => [:get]
  rb_match rb, 'hooks/sidebar/project/:project_id/:sprint_id',
          :to => 'rb_hooks_render#view_issues_sidebar', :via => [:get]

  rb_match rb, 'project/:project_id/backlogs', :to => 'rb_project_settings#project_settings', :via => [:get, :post]

  rb_match rb, 'projects/:project_id/genericboard',
          :to => 'rb_genericboards#index', :via => [:get]
  rb_match rb, 'projects/:project_id/genericboards/:genericboard_id',
          :to => 'rb_genericboards#show', :via => [:get]
  rb_match rb, 'projects/:project_id/genericboards/:genericboard_id/create',
          :to => 'rb_genericboards#create', :via => [:post, :put]
  rb_match rb, 'projects/:project_id/genericboards/:genericboard_id/update/:id',
          :to => 'rb_genericboards#update', :via => [:post, :put]

  ###### release notes ##############
  rb_match rb, '/releases/:id/generate_release_notes',
          :to => 'release_notes#generate_for_release', :via => [:get],
          :as => :generate_release_notes_for_release

  rb_match rb, '/versions/:id/generate_release_notes',
          :to => 'release_notes#generate', :via => [:get],
          :as => :generate_release_notes

  rb_match rb, 'release_notes_formats/preview',
          :to => 'release_notes_formats#preview', :via => [:patch],
          :as => :preview_release_notes_format

  rb_match rb, '/projects/:project_id/release_notes',
          :to => 'release_notes#index', :via => [:get],
          :as => :release_notes_overview
end

if Rails::VERSION::MAJOR < 3
ActionController::Routing::Routes.draw do |map|
  # Use rb/ as a URL 'namespace.' We're using a slightly different URL pattern
  # From Redmine so namespacing avoids any further problems down the line
  map.resource :rb, :only => :none do |rb|
    rb.resource   :task,             :except => :index,             :controller => :rb_tasks,           :as => "task/:id"
    rb.resources  :tasks,            :only => :index,               :controller => :rb_tasks,           :as => "tasks/:story_id"
    rb.resource   :taskboard,        :only => :show,                :controller => :rb_taskboards,      :as => "taskboards/:sprint_id"
    rb.resource   :taskboard,        :only => :current,             :controller => :rb_taskboards,      :as => "projects/:project_id/taskboard"

    rb_common_routes rb
  end
end

else
  resource :rb, :only => :none do |rb|

  # releases
#  resources :projects do
#    resources :releases, :only => [:index, :new,:show, :edit, :destroy, :snapshot], :controller => :rb_releases  do
#      get 'snapshot', :on => :member
#      post 'edit', :on => :member
#      post 'new', :on => :member
#    end
#  end

  rb_common_routes rb

  resources :genericboards, :controller => :rb_genericboards_admin, :via => [:get]
  
  resources :release, :controller => :rb_releases, :only => [:show, :destroy, :edit, :update], param: :release_id

  resources :issue_release, :controller => :rb_issue_release, param: :issue_release_id
  
  resources :sprint, :controller => :rb_sprints_roadmap, :only => [:show, :destroy, :edit, :update], param: :sprint_id
  
  resources :task, :except => :index, :controller => :rb_tasks
  # release notes
  resources :release_notes, :controller => :release_notes, :only => [:create, :update, :destroy]
  resources :release_notes_formats, :controller => :release_notes_formats, :except => [:index, :show]
  #
  rb_match rb, 'tasks/:story_id', :to => 'rb_tasks#index', :via => [:get]

  rb_match rb, 'taskboards/:sprint_id',
            :to => 'rb_taskboards#show', :via => [:get]
  rb_match rb, 'projects/:project_id/taskboard',
            :to => 'rb_taskboards#current', :via => [:get]
  end
  #release note plugins routes
  get '/projects/:project_id/release_notes',
    :to => 'release_notes#index',
    :as => :release_notes_overview

  resources :release_notes,
    :only => [:create, :update, :destroy]

  get "/versions/:id/generate_release_notes",
    :to => "release_notes#generate",
    :as => :generate_release_notes

  get "/releases/:id/generate_release_notes",
    :to => "release_notes#generate_for_release",
    :as => :generate_release_notes_for_release


  patch 'release_notes_formats/preview',
    :to => 'release_notes_formats#preview',
    :as => :preview_release_notes_format

  resources :release_notes_formats,
    :except => [:index, :show]

  get 'settings/plugin/redmine_release_notes?tab=formats',
    :to => 'settings#plugin',
    :as => :release_notes_formats_tab
end
