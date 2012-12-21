module RestClient
  module ResponseForException
    def method_missing symbol, *args
      if net_http_res.respond_to? symbol
        #warn "[warning] The response contained in an RestClient::Exception is now a RestClient::Response instead of a Net::HTTPResponse, please update your code"
        net_http_res.send symbol, *args
      else
        super
      end
    end
  end
end
