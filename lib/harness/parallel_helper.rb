require 'rspec_parallel'
require 'harness'
include BVT::Harness

module BVT::Harness
  module ParallelHelper

    YETI_HOME_PATH = File.join(File.dirname(__FILE__), "../../")
    SPEC_PATH      = File.join(YETI_HOME_PATH, "spec/")
    REPORT_PATH    = File.join(YETI_HOME_PATH, "reports/")

    def run_tests(thread_number, filter={}, rerun=false)
      options = {}
      options[:env_list] = get_parallel_users(thread_number)
      options[:thread_number] = thread_number
      options[:filter] = filter
      options[:case_folder] = SPEC_PATH
      options[:report_folder] = REPORT_PATH
      options[:rerun] = rerun
      options[:separate_rerun_report] = false if ENV["VCAP_BVT_CI_SINGLE_REPORT"] == "true"
      options[:show_pending] = true if ENV['VCAP_BVT_SHOW_PENDING'] == "true"

      rp = RspecParallel.new(options)
      rp.run_tests

      logging_failure(rp.case_info_list)

      {:case_number => rp.case_number, :failure_number => rp.failure_number,
       :pending_number => rp.pending_number, :interrupted => rp.interrupted}
    end

    def get_parallel_users(thread_number)
      all_users = RakeHelper.get_parallel_users
      if thread_number == 1
        one_user = RakeHelper.get_check_env_user(all_users)
        all_users = [one_user]
      end
      parallel_users = []
      i = 0
      all_users.each {|user|
        parallel_users << {"YETI_PARALLEL_USER" => user['email'], "YETI_PARALLEL_USER_PASSWD" => user['passwd']}
        i += 1
        break if i == thread_number
      }
      parallel_users
    end

    def logging_failure(case_info_list)
      return if case_info_list == []
      all_users = RakeHelper.get_parallel_users
      user = RakeHelper.get_check_env_user(all_users)
      session = CFSession.new(:admin => false,
                              :email => user['email'],
                              :passwd => user['passwd'],
                              :target => ENV['VCAP_BVT_TARGET'])
      case_info_list.each do |case_info|
        if case_info['status'] == 'fail'
          session.log.error case_info['test_name']
          session.log.error case_info['error_message']
          session.log.error case_info['error_stack_trace']
        end
      end
    end

    extend self
  end
end
