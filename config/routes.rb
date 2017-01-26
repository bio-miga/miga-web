Rails.application.routes.draw do
  # Static
  root 		   'static_pages#home'
  get 'about'	=> 'static_pages#about'
  get 'help'	=> 'static_pages#help'
  get 'contact'	=> 'static_pages#contact'
  # Login/sessions
  get 'sessions/new'
  get 'password_resets/new'
  get 'password_resets/edit'
  get 'signup'	=> 'users#new'
  get 'login'	=> 'sessions#new'
  post 'login'	=> 'sessions#create'
  delete 'logout' => 'sessions#destroy'
  # Projects
  get 'projects/:project_id/reference_datasets'    => 'projects#reference_datasets', as: :project_reference_datasets
  get 'projects/:id/reference_datasets/:dataset'   => 'projects#show_dataset', as: :reference_dataset
  get 'projects/:id/reference_datasets/:dataset/result/:result/:file' => 'projects#reference_dataset_result', as: :reference_dataset_result
  get 'projects/:project_id/query_datasets'        => 'query_datasets#index', as: :project_query_datasets
  get 'projects/:project_id/query_datasets/:ready' => 'query_datasets#index', as: :project_query_datasets_ready
  get 'projects/:id/result/:result/:file'          => 'projects#result', as: :project_result
  get 'projects/:id/ncbi_download'                 => 'projects#new_ncbi_download', as: :project_new_ncbi_download
  post 'projects/:id/ncbi_download'                => 'projects#create_ncbi_download', as: :project_create_ncbi_download
  post 'projects/:id/start_daemon'                 => 'projects#start_daemon', as: :project_start_daemon
  post 'projects/:id/stop_daemon'                  => 'projects#stop_daemon', as: :project_stop_daemon
  # Query datasets
  get 'query_datasets/all/:ready'                  => 'query_datasets#index', as: :query_datasets_ready
  get 'query_datasets/:id/result/:result/:file'    => 'query_datasets#result', as: :query_dataset_result
  get "query_datasets/:id/run_mytaxa_scan"         => "query_datasets#run_mytaxa_scan", as: :query_dataset_run_mytaxa_scan
  get "query_datasets/:id/run_distances"           => "query_datasets#run_distances", as: :query_dataset_run_distances
  # Medoid clusters
  get "medoid_clade/:project_id/:metric/:clade"    => "projects#medoid_clade", as: :medoid_clade
  get "medoid_clade/:project_id/:metric/:clade/as" => "projects#medoid_clade_as", as: :medoid_clade_as
  # RDP Classifier
  get "rdp_classify/:project_id/:ds_name"          => "projects#rdp_classify", as: :rdp_classify
  get "rdp_classify/:project_id/:ds_name/as"       => "projects#rdp_classify_as", as: :rdp_classify_as
  # Full resources
  resources :users
  resources :account_activations, only: [:edit]
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :projects, only: [:index, :new, :create, :destroy, :show]
  resources :query_datasets, only: [:index, :new, :create, :destroy, :show]

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
