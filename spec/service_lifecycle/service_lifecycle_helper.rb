module BVT::Spec
  module ServiceLifecycleHelper

  def auth_headers
    {"content-type"=>"application/json", "AUTHORIZATION" => @session.token}
  end

  def get_snapshots(service_id)
    easy = Curl::Easy.new("#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots")
    easy.headers = auth_headers
    easy.resolve_mode =:ipv4
    easy.http_get

    if easy.response_code == 501
      pending "Snapshot extension is disabled, return code=501"
    elsif easy.response_code != 200
      raise "code:#{easy.response_code}, body:#{easy.body_str}"
    end

    resp = easy.body_str
    resp.should_not == nil
    JSON.parse(resp)

  end

  def get_serialized_url(service_id, snapshot_id)
    easy = Curl::Easy.new("#{@session.TARGET}/services/v1/configurations/#{service_id}/serialized/url/snapshots/#{snapshot_id}")
    easy.headers = auth_headers
    easy.resolve_mode =:ipv4
    easy.http_get

    if easy.response_code == 501
      pending "Serialized API is disabled, return code=501"
    elsif easy.response_code != 200
      return nil
    end

    resp = easy.body_str
    result = JSON.parse(resp)
    result["url"]
  end

  def download_data(serialized_url)
    temp_file = Tempfile.new('serialized_data')
    File.open(temp_file.path, "wb+") do |f|
      c = Curl::Easy.new(serialized_url)
      c.on_body{|data| f.write(data)}
      c.perform
      c.response_code.should == 200
    end
    File.open(temp_file.path) do |f|
      f.size.should > 0
    end
    serialized_data_file = temp_file
  end

  def import_service_from_url(service_id, serialized_url)
    easy = Curl::Easy.new("#{@session.TARGET}/services/v1/configurations/#{service_id}/serialized/url")
    easy.headers = auth_headers
    payload = {"url" => serialized_url}
    easy.resolve_mode =:ipv4
    easy.http_put(JSON payload)

    resp = easy.body_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id, job["job_id"])
    job.should_not == nil
    snapshot_id = job["result"]["snapshot_id"]
    snapshot_id.should_not == nil
    snapshot_id
  end

  def import_service_from_data(service_id, serialized_data)
    post_data = []
    post_data << Curl::PostField.content("_method", "put")
    post_data << Curl::PostField.file("data_file", serialized_data.path)

    easy = Curl::Easy.new("#{@session.TARGET}/services/v1/configurations/#{service_id}/serialized/data")
    easy.multipart_form_post = true
    easy.headers = {"AUTHORIZATION" => @session.token}
    easy.resolve_mode =:ipv4
    easy.http_post(post_data)

    resp = easy.body_str
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
    services = JSON.parse content.body_str
    services.each do |_, instances|
      instances.each do |inst|
        if inst["label"] =~ /#{srv_name}/
          service_id = inst["credentials"]["name"]
          break
        end
      end
    end
    service_id
  end

  def create_serialized_url(service_id, snapshot_id)
    easy = Curl::Easy.new("#{@session.TARGET}/services/v1/configurations/#{service_id}/serialized/url/snapshots/#{snapshot_id}")
    easy.headers = auth_headers
    easy.resolve_mode =:ipv4
    easy.http_post ''

    easy.response_code.should == 200
    resp = easy.body_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id,job["job_id"])
    job["result"]["url"].should_not == nil
    job["result"]["url"]
  end

  def post_and_verify_service(service_manifest, app, key, data)
      url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
      app.get_response(:post, "/service/#{url}/#{key}", data)
      app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
  end

  def verify_service(service_manifest, app, key, data)
      url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
      app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
  end

  def create_snapshot(service_id)
    url = "#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots"
    easy = Curl::Easy.new(url)
    easy.headers = auth_headers
    easy.resolve_mode =:ipv4
    easy.http_post

    easy.response_code.should == 200
    resp = easy.body_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id, job["job_id"])
  end

  def get_snapshot(service_id, snapshot_id)
    easy = Curl::Easy.new("#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots/#{snapshot_id}")
    easy.headers = auth_headers
    easy.resolve_mode =:ipv4
    easy.http_get

    if easy.response_code != 200
      return nil
    end

    resp = easy.body_str
    resp.should_not == nil
    JSON.parse(resp)
  end

  def rollback_snapshot(service_id, snapshot_id)

    easy = Curl::Easy.new("#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots/#{snapshot_id}")
    easy.headers = auth_headers
    easy.resolve_mode =:ipv4
    easy.http_put ''

    easy.response_code.should == 200
    resp = easy.body_str
    resp.should_not == nil
    job = JSON.parse(resp)
    job = wait_job(service_id,job["job_id"])
    job.should_not == nil
    job["result"]["result"].should == "ok"
  end

  def delete_snapshot(service_id, snapshot_id)
    easy = Curl::Easy.new("#{@session.TARGET}/services/v1/configurations/#{service_id}/snapshots/#{snapshot_id}")
    easy.headers = auth_headers
    easy.resolve_mode =:ipv4
    easy.http_delete

    easy.response_code.should == 200
    resp = easy.body_str
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
    easy = Curl::Easy.new("#{@session.TARGET}/services/v1/configurations/#{service_id}/jobs/#{job_id}")
    easy.headers = auth_headers
    easy.resolve_mode =:ipv4
    easy.http_get

    resp = easy.body_str
    resp.should_not == nil
    JSON.parse(resp)
  end

  def job_completed?(job)
    return true if job["status"] == "completed" || job["status"] == "failed"
  end



  end
end



