require 'httparty'
require 'json'
require 'pp'

module OnTimeInterface
  
  def build_base_uri(account_name, query)
    return 'https://' + account_name + '.ontimenow.com/api' + query
  end

  def base_uri(uri)
    self.class.base_uri uri
  end

  def default_params(params)
    self.class.default_params params
  end

  def get(query, options)
    self.class.get(query, options)
  end

  def post(query, options, &block)
    self.class.post(query, options) { block }
  end
end  
