Rails.application.routes.draw do
  # Static
  root 		   'static_pages#home'
  get 'about'	=> 'static_pages#about'
  get 'help'	=> 'static_pages#help'
  get 'contact'	=> 'static_pages#contact'

  # Lair and daemons
  get 'lair'       => 'projects#lair',       as: :lair
  get 'lair/toggle' => 'projects#lair_toggle', as: :lair_toggle
  get 'lair/toggle_daemon/:id' => 'projects#daemon_toggle', as: :daemon_toggle
  get 'lair/start_all_daemons' =>
    'projects#daemon_start_all', as: :daemon_start_all
  get 'lair/stop_all_daemons'  =>
    'projects#daemon_stop_all',  as: :daemon_stop_all

  # Login/sessions
  get 'sessions/new'
  get 'password_resets/new'
  get 'password_resets/edit'
  get 'signup'	=> 'users#new'
  get 'login'	=> 'sessions#new'
  post 'login'	=> 'sessions#create'
  delete 'logout' => 'sessions#destroy'

  # Projects
  get 'projects/:project_id/reference_datasets' =>
    'projects#reference_datasets', as: :project_reference_datasets
  get 'projects/:id/reference_datasets/:dataset' =>
    'projects#show_dataset', as: :reference_dataset
  get 'projects/:id/reference_datasets/:dataset/result/:result/:file' =>
    'projects#reference_dataset_result', as: :reference_dataset_result
  get 'projects/:id/search' =>
    'projects#search', as: :project_search
  get 'projects/:project_id/query_datasets' =>
    'query_datasets#index', as: :project_query_datasets
  get 'projects/:id/result/:result/:file' =>
    'projects#result', as: :project_result
  get 'projects/:id/result/:result' =>
    'projects#result_partial', as: :project_result_partial
  get 'projects/:id/ncbi_download' =>
    'projects#new_ncbi_download', as: :project_new_ncbi_download
  post 'projects/:id/ncbi_download' =>
    'projects#create_ncbi_download', as: :project_create_ncbi_download
  get 'projects/:id/new_reference' =>
    'projects#new_reference', as: :project_new_reference
  post 'projects/:id/new_reference' =>
    'projects#new_reference', as: :project_create_reference

  # Query datasets
  get 'query_datasets/:id/result/:result/:file' =>
    'query_datasets#result', as: :query_dataset_result
  get 'query_datasets/:id/run_mytaxa_scan' =>
    'query_datasets#run_mytaxa_scan', as: :query_dataset_run_mytaxa_scan
  get 'query_datasets/:id/run_distances' =>
    'query_datasets#run_distances', as: :query_dataset_run_distances
  post 'query_datasets/:id/unread' =>
    'query_datasets#mark_unread', as: :query_dataset_mark_unread
  get 'query_datasets/:id/reactivate_dataset' =>
    'query_datasets#reactivate', as: :query_dataset_reactivate

  # Medoid clusters
  get 'medoid_clade/:project_id/:metric/:clade' =>
    'projects#medoid_clade', as: :medoid_clade
  get 'medoid_clade/:project_id/:metric/:clade/as' =>
    'projects#medoid_clade_as', as: :medoid_clade_as

  # RDP Classifier
  get 'rdp_classify/:project_id/:ds_name' =>
    'projects#rdp_classify', as: :rdp_classify
  get 'rdp_classify/:project_id/:ds_name/as' =>
    'projects#rdp_classify_as', as: :rdp_classify_as

  # Users
  resources :users
  get 'dashboard' => 'users#dashboard', as: :dashboard
  get 'admin' => 'users#admin', as: :admin
  get 'unactivated_users' => 'users#unactivated_users', as: :unactivated_users
  post 'activate_user' => 'users#activate_user'

  # Full resources
  resources :account_activations, only: [:edit]
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :projects, only: [:index, :new, :create, :destroy, :show]
  resources :query_datasets, only: [:index, :new, :create, :destroy, :show]
end
