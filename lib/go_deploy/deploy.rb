require 'yaml'
require_relative 'string'
require_relative 'console'
require 'net/ssh'
require 'securerandom'
require 'net/scp'
# frozen_string_literal: true

module GoDeploy
  # App go-deploy
  class Deploy
    TMP_DIR = '/tmp'.freeze
    attr_accessor :config

    def initialize
      super
      begin
        error_message = 'Please specify an order e.g.go-deploy production deploy or go-deploy production logs'
        @file_name = ARGV[0]
        @action = ARGV[1]
        puts error_message.red and exit if @file_name.nil? && @action.nil?

        yaml_file = File.join(Dir.pwd, "#{@file_name}.yaml")

        self.config = YAML.load_file(yaml_file)
        @console = Console.new(config)
        @service = config['service']
      rescue StandardError => e
        puts e.message.red
        exit
      end
    end

    def run
      case @action.upcase
      when 'DEPLOY'
        deploy_go
      when 'LOGS'
        logs
      end
    end

    private

    def ssh
      return @ssh if defined? @ssh

      @ssh = Net::SSH.start(config['host'], config['user'], ssh_options)
    end

    def ssh_options
      {
        keys: [config['passphrase']],
        forward_agent: true,
        paranoid: true
      }
    end

    def deploy_go
      # Step 1
      wrapper
      # Step 2
      git_check
      # Step 3
      git_clone
      # Step 4
      set_env
      # Step 5
      build_go
      # Stop 6
      stop_go_service_and_copy_files
      # Stop 7
      remove_files
      # Stop 8
      start_go_service if @is_restart
    end

    def logs
      @service_name = @service['name']
      @console.sudo_exec(ssh: ssh, command: "sudo journalctl -u #{@service_name}.service -f", is_show_color: false)
    end

    def wrapper
      puts 'Step 1 git:wrapper'.green
      @git_ssh_name = "git-ssh-#{SecureRandom.hex(10)}.sh"
      @git_wrapper_path = "#{TMP_DIR}/#{@git_ssh_name}"

      @console.exec(ssh: ssh, command: "mkdir -p #{File.dirname(@git_wrapper_path).shellescape}")
      file = StringIO.new("#!/bin/sh -e\nexec /usr/bin/env ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no \"$@\"\n")
      @console.log(command: "Uploading #{@git_wrapper_path}") if @ssh.scp.upload!(file, @git_wrapper_path)

      @console.exec(ssh: ssh, command: "chmod 700 #{@git_wrapper_path.shellescape}")
    end

    def git_check
      puts 'Step 2 git:check'.green
      @console.exec(ssh: ssh, command: "git ls-remote #{@service['git_repo_url']} HEAD")
    end

    def git_clone
      @deploy_to = @service['deploy_to']
      puts 'Step 3 git:clone'.green
      @console.exec(ssh: ssh, command: "mkdir -p #{@deploy_to}")
      @console.exec(ssh: ssh, command: "git clone #{@service['git_repo_url']} #{@deploy_to}/repo")
      # clean up files
      @service['copy_files'].each do |file_name|
        @console.exec(ssh: ssh, command: "rm -rf #{@deploy_to}/#{file_name}")
      end
    end

    def set_env
      project_env_file = "#{@deploy_to}/repo/.env"
      @env_file = @service['env_file']
      puts 'Step 4 set:env'.green
      @console.log(command: "Uploading #{project_env_file}") if ssh.scp.upload!(@env_file, project_env_file)
    end

    def build_go
      puts 'Step 5 build:go'.green
      @console.exec(ssh: ssh, command: "cd #{@service['deploy_to']}/repo && go build -o #{@service['name']}")
    end

    def stop_go_service_and_copy_files
      @service_name = @service['name']
      @is_restart = @service['is_restart']
      puts "Step 6 systemctl:stop:#{@service_name}".green if @is_restart
      @console.sudo_exec(ssh: ssh, command: "sudo systemctl stop #{@service_name}.service")
      @console.exec(ssh: ssh, command: "cd #{@deploy_to}/repo && mv #{@env_file} #{@deploy_to}")

      @service['copy_files'].each do |file_name|
        @console.exec(ssh: ssh, command: "cd #{@deploy_to}/repo && mv #{file_name} #{@deploy_to}")
      end

      @console.exec(ssh: ssh, command: "cd #{@deploy_to}/repo && mv #{@service_name} #{@deploy_to}")
    end

    def remove_files
      puts 'Step 7 removed:files'.green
      @console.exec(ssh: ssh, command: "cd #{@deploy_to}/repo && mv #{@service_name} #{@deploy_to}")
      @console.exec(ssh: ssh, command: "rm -rf #{@deploy_to}/repo")
      @console.exec(ssh: ssh, command: "rm -rf #{@git_wrapper_path}")
      @console.exec(ssh: ssh, command: 'rm -rf /tmp/git-ssh*')
    end

    def start_go_service
      puts "Step 8 systemctl:start#{@service_name}".green
      @console.sudo_exec(ssh: ssh, command: "sudo systemctl start #{@service_name}.service")
    end
  end
end
