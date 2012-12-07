module BVT::Spec
  module ServiceLifecycleHelper

  SERVICE_LIFECYCLE_CONFIG = ENV['VCAP_BVT_DEPLOY_MANIFEST'] || File.join(File.dirname(__FILE__), "service_lifecycle.yml")
  SERVICE_CONFIG = (YAML.load_file(SERVICE_LIFECYCLE_CONFIG) rescue {"properties"=>{"service_plans"=>{}}})
  SERVICE_PLAN = ENV['VCAP_BVT_SERVICE_PLAN'] || "free"
  SERVICE_SNAPSHOT_QUOTA = {}
  SERVICE_CONFIG['properties']['service_plans'].each do |service,config|
    SERVICE_SNAPSHOT_QUOTA[service] = config[SERVICE_PLAN]["configuration"] if config.include?(SERVICE_PLAN)
  end
  DEFAULT_SNAPSHOT_QUOTA = 5

  def snapshot_quota(service)
    q = SERVICE_SNAPSHOT_QUOTA[service] || {}
    q = q["lifecycle"] || {}
    q = q["snapshot"] || {}
    q["quota"] || DEFAULT_SNAPSHOT_QUOTA
  end

  def auth_headers
    {"content-type"=>"application/json", "AUTHORIZATION" => @session.token}
  end

  def get_snapshots(service_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots"
    r = RestClient.get url, :content_type => "application/json", :AUTHORIZATION => @session.token

    if r.code == 501
      pending "Snapshot extension is disabled, return code=501"
    elsif r.code != 200
      raise "code:#{r.code}, body:#{r.to_str}"
    end

    resp = r.to_str
    resp.should_not == nil
    JSON.parse(resp)
  end

  def get_serialized_url(service_id, snapshot_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/serialized/url/snapshots/#{snapshot_id}"
    r = RestClient.get url, :content_type => "application/json", :AUTHORIZATION => @session.token

    if r.code == 501
      pending "Serialized API is disabled, return code=501"
    elsif r.code != 200
      return nil
    end

    resp = r.to_str
    result = JSON.parse(resp)
    result["url"]
  end

  def download_data(serialized_url)
    temp_file = Tempfile.new('serialized_data')
    File.open(temp_file.path, "wb+") do |f|
      c = RestClient.get serialized_url
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
    RestClient.put url, :url => serialized_url, :content_type => "application/json", :AUTHORIZATION => @session.token

    resp = r.to_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id, job["job_id"])
    job.should_not == nil
    snapshot_id = job["result"]["snapshot_id"]
    snapshot_id.should_not == nil
    snapshot_id
  end

  def import_service_from_data(service_id, serialized_data)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/serialized/data"
    RestClient.post url, :data_file => File.new(serialized_data.path, "rb"),
                         :content_type => "application/json", :AUTHORIZATION => @session.token

    resp = r.to_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id, job["job_id"])
    job.should_not == nil
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
    RestClient.post url, '', :content_type => "application/json", :AUTHORIZATION => @session.token

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
    RestClient.post url, :content_type => "application/json", :AUTHORIZATION => @session.token

    r.code.should == 200
    resp = r.to_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id, job["job_id"])
  end

  def get_snapshot(service_id, snapshot_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots/#{snapshot_id}"
    RestClient.get url, :content_type => "application/json", :AUTHORIZATION => @session.token

    if r.code != 200
      return nil
    end

    resp = r.to_str
    resp.should_not == nil
    JSON.parse(resp)
  end

  def rollback_snapshot(service_id, snapshot_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots/#{snapshot_id}"
    RestClient.put url, '', :content_type => "application/json", :AUTHORIZATION => @session.token

    r.code.should == 200
    resp = r.to_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id,job["job_id"])
    job.should_not == nil
    job["result"]["result"].should == "ok"
  end

  def delete_snapshot(service_id, snapshot_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots/#{snapshot_id}"
    RestClient.delete url, :content_type => "application/json", :AUTHORIZATION => @session.token

    r.code.should == 200
    resp = r.to_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id, job["job_id"])
    job.should_not == nil
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
    RestClient.get url, :content_type => "application/json", :AUTHORIZATION => @session.token

    resp = r.to_str
    resp.should_not == nil
    JSON.parse(resp)
  end

  def job_completed?(job)
    return true if job["status"] == "completed" || job["status"] == "failed"
  end



  end
end



