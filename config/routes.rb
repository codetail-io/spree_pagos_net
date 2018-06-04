Rails.application.routes.draw do
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
    get '/spree/pagos_net/credit_card/:id', to: "pagos_net#credit_card", as: :credit_card
    get '/spree/pagos_net/cash_payment/:id', to: "pagos_net#cash_payment", as: :cash_payment
    get '/spree/pagos_net/ebaking/:id', to: "pagos_net#ebaking", as: :ebaking

  end
  get '/tushop_webservice/action.WSDL', to: redirect('/tushop_webservice/action')
  wash_out :tushop_webservice

end
