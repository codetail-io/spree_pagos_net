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
  patch '/spree/pagos_net', to: "pagos_net#update", as: :pagos_net_update
end
get '/tushop_webservice/action.WSDL', to: redirect('/tushop_webservice/action')
wash_out :tushop_webservice
