module Spree
  class PaymentMethod::PagosNet < PaymentMethod

    def provider_class
      ActiveMerchant::Billing::PagosNet
    end

    def provider
      @provider ||= provider_class.new
    end

    def source_required?
      false
    end
    def checkout_url
      "#{preferred_server}/api/checkout"
    end

    def cnb_form_fields order, result_url, server_url
      provider.cnb_form_fields amount: order.total,
                               currency: order.currency,
                               description: preferred_order_description,
                               order_id: order.id,
                               result_url: result_url,
                               server_url: server_url,
                               sandbox: preferred_test_mode ? 1 : 0
    end

    def check_signature data, signature
      provider.check_signature data, signature
    end
  end
end
