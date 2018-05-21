class PagosnetCreditcard

  def self.generate_iframe_pagosnet_creditcard(code_transaction, url_return = nil)
    red_url = url_return
    # entidad = 109
    entidad = ENV['COMPANY_CODE']
    # red_url = 'https://www.tushopbolivia.com'
    # if Rails.env.production?
    #   red_url = url_return
    #   entidad = 109
    # end

    result = ENV['URL_PAGOSNET_CREDITCARD'] + "?entidad=#{entidad}&ref=#{code_transaction}&red=#{red_url}"

    return result
  end

  def self.data_encrypt_pagosnet_creditcard(codigo_recaudacion)
    plaintext = Digest::MD5.digest("cliente=#{ENV['NRO_CLIENT']}&entidad=#{ENV['ENTIDAD']}&ref=#{codigo_recaudacion}")
    key = Base64.decode64(ENV['KEY_AUTHENTICATE'])

    cipher = OpenSSL::Cipher.new('AES-128-ECB')
    cipher.encrypt
    cipher.key = key
    msg_aes = cipher.update(plaintext) + cipher.final

    key_crypt = ERB::Util.url_encode(Base64.encode64(msg_aes))

    return { plaintext: plaintext, key: key, msg_aes: msg_aes, key_crypt: key_crypt }
  rescue
    nil
  end

  def self.disabled_method_paymeth
    result = [:paypal]

    if Option.value_for(:apply_pagosnet_creditcard) == 0
      result << :pagos_net_creditcard
    end

    return result
  end
end
