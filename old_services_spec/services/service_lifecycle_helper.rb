include BVT::Harness

module BVT::Spec
  module ServiceLifecycleHelper

  def snapshot_quota(service)
    q = service_snapshot_quota[service] || {}
    q = q["lifecycle"] || {}
    q = q["snapshot"] || {}
    q["quota"] || default_snapshot_quota
  end

  def auth_headers
    {"content-type"=>"application/json", "AUTHORIZATION" => @session.token.auth_header}
  end

  def get_snapshots(service_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots"
    begin
      r = RestClient.get(url, auth_headers)
    rescue RestClient::Exception => e
      if e.http_code == 501
        pending "Snapshot extension is disabled, return code=501"
      elsif e.http_code != 200
        raise "code:#{e.http_code}, body:#{e.to_s}"
      end
    end

    resp = r.to_str
    resp.should_not == nil
    JSON.parse(resp)
  end

  def get_serialized_url(service_id, snapshot_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/serialized/url/snapshots/#{snapshot_id}"
    begin
      r = RestClient.get(url, auth_headers)
    rescue RestClient::Exception => e
      if e.http_code == 501
        pending "Serialized API is disabled, return code=501"
      elsif e.http_code != 200
        return nil
      end
    end

    return nil if r.code != 200

    resp = r.to_str
    result = JSON.parse(resp)
    result["url"]
  end

  def download_data(serialized_url)
    temp_file = Tempfile.new('serialized_data')
    File.open(temp_file.path, "wb+") do |f|
      c = RestClient.get(serialized_url)
      c.code.should == 200
      f.write(c.to_str)
    end
    File.open(temp_file.path) do |f|
      f.size.should > 0
    end
    serialized_data_file = temp_file
  end

  def import_service_from_url(service_id, serialized_url)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/serialized/url"
    r = RestClient.put(url, {:url=>serialized_url}.to_json, auth_headers)

    resp = r.to_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id, job["job_id"])
    job.should_not be_nil, "The job cannot be completed in 8 seconds"
    snapshot_id = job["result"]["snapshot_id"]
    snapshot_id.should_not == nil
    snapshot_id
  end

  def import_service_from_data(service_id, serialized_data)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/serialized/data"
    r = RestClient.put(url, {:data_file=>File.new(serialized_data.path)}, auth_headers)

    resp = r.to_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id, job["job_id"])
    job.should_not be_nil, "The job cannot be completed in 8 seconds"
    snapshot_id = job["result"]["snapshot_id"]
    snapshot_id.should_not == nil
    snapshot_id
  end

  def parse_service_id(content, srv_name)
    service_id = nil
    services = JSON.parse(content.to_str)
    services.each do |k, v|
      v.each do |srv|
        if srv["name"] =~ /#{srv_name}/
          service_id = srv["credentials"]["name"]
          break
        end
      end
    end
    service_id
  end

  def create_serialized_url(service_id, snapshot_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/serialized/url/snapshots/#{snapshot_id}"
    r = RestClient.post(url, '', auth_headers)

    r.code.should == 200
    resp = r.to_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id,job["job_id"])
    job["result"]["url"].should_not == nil
    job["result"]["url"]
  end

  def post_and_verify_service(service_manifest, app, key, data)
      url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
      app.get_response(:post, "/service/#{url}/#{key}", data)
      app.get_response(:get, "/service/#{url}/#{key}").to_str.should == data
  end

  def verify_service(service_manifest, app, key, data)
      url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
      app.get_response(:get, "/service/#{url}/#{key}").to_str.should == data
  end

  def create_snapshot(service_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots"
    r = RestClient.post(url, '', auth_headers)

    r.code.should == 200
    resp = r.to_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id, job["job_id"])
  end

  def get_snapshot(service_id, snapshot_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots/#{snapshot_id}"
    begin
      r = RestClient.get(url, auth_headers)
    rescue
      return nil
    end

    if r.code != 200
      return nil
    end

    resp = r.to_str
    resp.should_not == nil
    JSON.parse(resp)
  end

  def rollback_snapshot(service_id, snapshot_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots/#{snapshot_id}"
    r = RestClient.put(url, '', auth_headers)

    r.code.should == 200
    resp = r.to_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id,job["job_id"])
    job.should_not be_nil, "The job cannot be completed in 8 seconds"
    job["result"]["result"].should == "ok"
  end

  def delete_snapshot(service_id, snapshot_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots/#{snapshot_id}"
    r = RestClient.delete(url, auth_headers)

    r.code.should == 200
    resp = r.to_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id, job["job_id"])
    job.should_not be_nil, "The job cannot be completed in 8 seconds"
    job["result"]["result"].should == "ok"

  end

  def wait_job(service_id, job_id)
    timeout = 8
    sleep_time = 1
    while timeout > 0
      sleep sleep_time
      timeout -= sleep_time

      job = get_job(service_id, job_id)
      return job if job_completed?(job)
    end
    # failed
    nil
  end

  def get_job(service_id, job_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/jobs/#{job_id}"
    r = RestClient.get(url, auth_headers)

    resp = r.to_str
    resp.should_not == nil
    JSON.parse(resp)
  end

  def job_completed?(job)
    return true if job["status"] == "completed" || job["status"] == "failed"
  end

  def create_items_and_verify_rabbit(service_manifest, app, items)
    cred = app.services[0].manifest[:entity][:credentials]
    url = "http://#{cred[:username]}:#{cred[:password]}@#{cred[:host]}:#{cred[:admin_port]}/api"
    resource = RestClient::Resource.new url
    items.each do |type, objects|
      objects.each do |object|
        name, durable = object
        #post is not supported for this path
        resource["#{type}/#{cred[:vhost]}/#{name}"].put({:durable => durable}.to_json, :content_type => "application/json")
      end
    end

    get_and_verify_rabbit(service_manifest, app, items, nil)
  end

  def clear_and_verify_rabbit(service_manifest, app, items)
    cred = app.services[0].manifest[:entity][:credentials]
    url = "http://#{cred[:username]}:#{cred[:password]}@#{cred[:host]}:#{cred[:admin_port]}/api"
    resource = RestClient::Resource.new url
    items.each do |type, objects|
      objects.each { |object| resource["#{type}/#{cred[:vhost]}/#{object[0]}"].delete }
    end

    get_and_verify_rabbit(service_manifest, app, nil, items)
  end

  def get_and_verify_rabbit(service_manifest, app, included_items, excluded_items)
    cred = app.services[0].manifest[:entity][:credentials]
    url = "http://#{cred[:username]}:#{cred[:password]}@#{cred[:host]}:#{cred[:admin_port]}/api"
    resource = RestClient::Resource.new(url)
    queues = JSON.parse(resource["queues"].get).map { |queue| [queue["name"], queue["durable"]] }
    exchanges = JSON.parse(resource["exchanges"].get).map { |exchange| [exchange["name"], exchange["durable"]] }
    server_items = queues + exchanges
    included_items.values.flatten(1).each { |item| server_items.include?(item).should == true } if included_items
    excluded_items.values.flatten(1).each { |item| server_items.include?(item).should == false } if excluded_items
  end

  end
end
