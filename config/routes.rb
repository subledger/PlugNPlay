PlugNPlay::Application.routes.draw do
  namespace :api do
    api version: 1, module: "v1" do
      post "event/trigger", to: "event#trigger"
    end
  end

  resource :setup, only: [:new, :create, :show]

  get  "simulate/simulate_charge_buyer", as: :simulate_charge_buyer
  post "simulate/charge_buyer", as: :charge_buyer
  get  "simulate/simulate_payout_referrer", as: :simulate_payout_referrer
  post "simulate/payout_referrer", as: :payout_referrer
  get  "simulate/simulate_payout_publisher", as: :simulate_payout_publisher
  post "simulate/payout_publisher", as: :payout_publisher
  get  "simulate/simulate_payout_distributor", as: :simulate_payout_distributor
  post "simulate/payout_distributor", as: :payout_distributor

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root "setups#show"

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
