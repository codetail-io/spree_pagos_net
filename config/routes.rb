Spree::Core::Engine.add_routes do
  # Add your extension routes here
  resources :orders do
    resource :checkout, :controller => 'checkout' do
      member do
        get :pagos_net_result
        get :pagos_net_status
      end
    end
  end

  post '/pagos_net_status/:payment_method_id' => 'pagos_net#update', :as => :pagos_net_update
end
