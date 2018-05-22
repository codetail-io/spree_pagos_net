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
  end
end
