require "examine/version"

require 'down'
require 'mkmf'
require 'socket'
require 'thor'

module Examine
  class Error < StandardError; end

  module CLI
    class Clair < Thor
      DOWNLOAD_PATH = 'https://github.com/arminc/clair-scanner/releases/download/v12/'

      method_option :clair_url, desc: 'clair url', default: 'http://localhost:6060', type: :string
      desc 'start', 'start a clair server'
      def start
        db_pid = spawn 'docker run -d --name clair-db arminc/clair-db:latest'
        command = 'docker ps --filter="name=clair-db" --filter="status=running" --filter="expose=5432/tcp" | grep -v CONT'
        print '.' until system(command)
        puts "clair-db started. (PID: #{db_pid})"

        clair_pid = spawn 'docker run --restart=unless-stopped -p 6060:6060 --link clair-db:postgres -d --name clair arminc/clair-local-scan:latest'

        command = 'docker ps --filter="name=clair" --filter="status=running" --filter="expose=6060/tcp" | grep -v CONT'
        print '.' until system(command)
        print '.' until system("curl -s #{options[:clair_url]}/v1/namespaces > /dev/null")
        puts "clair-local-scan started. (PID: #{clair_pid})"
      end

      method_option :ip, desc: 'ip address', default: nil, type: :string
      method_option :clair_url, desc: 'clair url', default: 'http://localhost:6060', type: :string
      desc 'scan <image>', 'scan a specific image'
      def scan(image)
        start unless started?

        ip = options[:ip] || Socket.ip_address_list[1].ip_address
        system "docker pull #{image}"
        unless (clair_exe = find_executable('clair-scanner'))
          download_path = case RUBY_PLATFORM
          when 'x86_64-linux'
            URI.join(DOWNLOAD_PATH, 'clair-scanner_linux_386').to_s
          else
            raise 'clair-scanner could not be found in your PATH. Download from https://github.com/arminc/clair-scanner/releases'
          end
          clair_exe = File.join(Dir.tmpdir, 'clair-scanner')
          Down.download(download_path, destination: clair_exe)
          `chmod +x #{clair_exe}`
        end
        system "#{clair_exe} -c #{options[:clair_url]} --ip #{ip} #{image}"
      end

      desc 'status', 'status of clair server'
      def status
        system "docker ps -a | grep clair"
      end

      desc 'stop', 'stop all clair servers'
      def stop
        system "docker stop $(docker ps | grep -v CONT | grep clair- | awk '{ print $1 }')"
        system "docker system prune -f"
      end

      private

      def started?
        status
      end
    end

    class Application < Thor
      package_name 'examine'

      desc 'clair', 'manage clair'
      subcommand :clair, Examine::CLI::Clair
    end
  end
end
