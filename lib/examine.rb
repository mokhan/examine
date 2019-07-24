require "examine/version"

require 'down'
require 'socket'
require 'thor'
require 'timeout'

module Examine
  class Error < StandardError; end

  module CLI
    class Clair < Thor
      DOWNLOAD_PATH = 'https://github.com/arminc/clair-scanner/releases/download/v12/'

      method_option :clair_url, desc: 'clair url', default: 'http://localhost:6060', type: :string
      desc 'start', 'start a clair server'
      def start
        ensure_docker_installed!
        spawn 'docker run -d --name clair-db arminc/clair-db:latest'
        wait_until('docker ps --filter="name=clair-db" --filter="status=running" --filter="expose=5432/tcp" | grep -v CONT')

        spawn 'docker run --restart=unless-stopped -p 6060:6060 --link clair-db:postgres -d --name clair arminc/clair-local-scan:latest'
        wait_until('docker ps --filter="name=clair" --filter="status=running" --filter="expose=6060/tcp" | grep -v CONT')
        wait_until("curl -s #{options[:clair_url]}/v1/namespaces > /dev/null")
      end

      method_option :ip, desc: 'ip address', default: nil, type: :string
      method_option :clair_url, desc: 'clair url', default: 'http://localhost:6060', type: :string
      desc 'scan <image>', 'scan a specific image'
      def scan(image)
        start unless started?

        ip = options[:ip] || Socket.ip_address_list[1].ip_address
        system "docker pull #{image}"
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

      def clair_exe
        @clair_exe ||= executable_exists?('clair-scanner') || download_clair
      end

      def executable_exists?(exe)
        found = ENV['PATH'].split(':').find do |x|
          File.exist?(File.join(x, exe))
        end
        return File.join(found, exe) if found
      end

      def download_clair
        File.join(Dir.tmpdir, 'clair-scanner').tap do |exe|
          Down.download(clair_download_path, destination: exe)
          `chmod +x #{exe}`
        end
      end

      def clair_download_path
        platform = Gem::Platform.local
        exe = {
          'x86-darwin' => 'clair-scanner_darwin_386',
          'x86-linux' => 'clair-scanner_linux_386',
          'x86_64-darwin' => 'clair-scanner_darwin_amd64',
          'x86_64-linux' => 'clair-scanner_linux_amd64',
        }["#{platform.cpu}-#{platform.os}"]
        return URI.join(DOWNLOAD_PATH, exe).to_s if exe

        raise 'clair-scanner could not be found in your PATH. Download from https://github.com/arminc/clair-scanner/releases'
      end

      def wait
        print '.'
        sleep 1
      end

      def wait_until(command)
        Timeout.timeout(60, nil, command) do
          wait until system(command)
        end
      end

      def ensure_docker_installed!
        raise 'docker was not detected on the system' unless executable_exists?('docker')
      end
    end

    class Application < Thor
      package_name 'examine'

      desc 'clair', 'manage clair'
      subcommand :clair, Examine::CLI::Clair
    end
  end
end
