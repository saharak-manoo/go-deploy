# frozen_string_literal: true

module GoDeploy
  # Console cli linux
  class Console
    def initialize(config)
      @config = config
    end

    def log(command:, is_show_remote_name: true, is_show_color: true)
      puts is_show_color ? "\t#{command}".yellow : "\t#{command}"
      show_remote_name if is_show_remote_name
    end

    def exec(ssh:, command:)
      log(command: command)
      ssh.open_channel do |channel|
        channel.exec(command) do |_ch, success|
          show_remote_name(is_success: success)
        end
      end
    end

    def file_exists?(ssh:, path:)
      results = []
      ssh.exec!("if [ -e '#{path}' ]; then echo -n 'true'; fi") do |_ch, _stream, out|
        results << (out == 'true')
      end

      results.all?
    end

    def sudo_exec(ssh:, command:, is_show_color: true)
      ssh.open_channel do |channel|
        channel.request_pty do |_c, success|
          raise 'Could not request pty' unless success

          channel.exec(command)
          channel.on_data do |_c, cmd|
            log(command: cmd, is_show_remote_name: false, is_show_color: is_show_color)

            channel.send_data "#{@config['password']}\n" if cmd[/\[sudo\]|Password/i]
          end
        end
      end

      ssh.loop
    end

    def show_remote_name(is_success: true)
      if is_success
        puts "      ✔ #{@config['user']}@#{@config['host']}".green
      else
        puts "      ✘ #{@config['user']}@#{@config['host']}".red
      end
    end
  end
end
