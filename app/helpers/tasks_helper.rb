module TasksHelper
  
  def get_connection
    ot = OnTimeConnection.new(APP_CONFIG['account_name'], ENV['ontime_client_id'], ENV['ontime_client_secret'])
  end
  
  def lookup_by_id(items, id)
    found = nil
    pp items
    items.each do |item|
      if item.id == id
        found = item
        break
      end
    end
    return found
  end
  
end
