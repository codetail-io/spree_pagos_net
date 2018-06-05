module Spree
  class PaymentMethod::PagosNet < PaymentMethod
    preference :server, :string, default: 'http://localhost:3000'
    preference :account_pagos_net, :string
    preference :password_pagos_net, :string
    preference :order_description, :string, default: -> { Spree::Store.current.name }
    preference :soap_url_pagos_net, :string, default: 'http://test.sintesis.com.bo/WSApp-war/ComelecWS?WSDL'
    preference :company_code_pagos_net, :string, default: '109'
    preference :credit_card_pagos_net, :string, default: 'https://test.sintesis.com.bo/payment/#/pay'
    preference :credit_card_nro_client, :string, default: 68
    preference :credit_card_entity, :string, default: 115
    preference :credit_card_key_authenticate, :string, default: 'JEn1jJsD5hFrip4jzHODyA=='
    preference :public_key, :string, default: ''
    preference :private_key, :string, default: ''
    preference :test_mode, :boolean, default: true

    def provider_class
      ActiveMerchant::Billing::PagosNet
    end

    def provider
      @provider ||= provider_class.new(preferred_public_key, preferred_private_key)
    end

    def source_required?
      false
    end

    def checkout_url
      "#{preferred_server}/spree/pagos_net"
    end

    def cnb_form_fields(order, result_url, server_url)
      provider.cnb_form_fields amount: order.total,
                               currency: order.currency,
                               description: preferred_order_description,
                               order_id: order.id,
                               result_url: result_url,
                               server_url: server_url,
                               account_pagos_net: '',
                               password_pagos_net: '',
                               sandbox: preferred_test_mode ? 1 : 0
    end

    def check_signature(data, signature)
      provider.check_signature data, signature
    end
  end
end
