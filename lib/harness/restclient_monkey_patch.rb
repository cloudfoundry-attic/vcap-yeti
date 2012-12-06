module ResponseForException
  def method_missing symbol, *args
    if net_http_res.respond_to? symbol
      net_http_res.send symbol, *args
    else
      super
    end
  end
end
