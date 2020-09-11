# frozen_string_literal: true

module Examine
  module CLI
    # Entrypoint into the `examine clair` subcommand.
    class Clair < Thor
      DOWNLOAD_PATH = 'https://github.com/arminc/clair-scanner/releases/download/'
      EXECUTABLES = {
        'x86-darwin' => 'clair-scanner_darwin_386',
        'x86-linux' => 'clair-scanner_linux_386',
        'x86_64-darwin' => 'clair-scanner_darwin_amd64',
        'x86_64-linux' => 'clair-scanner_linux_amd64'
      }.freeze

      class_option :scanner_version, desc: 'Version of the clair-scanner', default: 'v12', type: :string
      class_option :url, desc: 'clair url', default: 'http://localhost:6060', type: :string

      desc 'start', 'start a clair server'
      def start
        ensure_docker_installed!
        return if started?

        spawn clair_db
        wait_until clair_db_running?

        spawn clair_local_scan
        wait_until clair_local_scan_running?
        wait_until clair_local_scan_api_reachable?
      end

      method_option :ip, desc: 'ip address', default: nil, type: :string
      method_option :report, desc: 'report file', default: 'report.json', type: :string
      method_option :log, desc: 'log file', default: 'clair.log', type: :string
      method_option :whitelist, desc: 'whitelist file', default: nil, type: :string
      desc 'scan <image>', 'scan a specific docker image. E.g mokhan/minbox:latest'
      def scan(image)
        start

        system "docker pull #{image}"
        system scan_command_for(image, options)
      end

      desc 'status', 'status of clair server'
      def status
        system 'docker ps -a | grep clair'
      end

      desc 'stop', 'stop all clair servers'
      def stop
        system "docker stop $(docker ps | grep -v CONT | grep clair- | awk '{ print $1 }')"
        system 'docker system prune -f'
      end

      private

      def started?
        status
      end

      def clair_exe
        @clair_exe ||= executable_exists?('clair-scanner') || download_clair
      end

      def scan_command_for(image, options)
        command = [
          clair_exe, "-c #{options[:url]}",
          "--ip #{clair_ip}",
          '--threshold Low',
          '--reportAll=false',
          "-r #{options[:report]}", "-l #{options[:log]}", image
        ]
        command.insert(-2, "-w #{options[:whitelist]}") if options[:whitelist]
        command.join(' ')
      end

      def clair_ip
        options[:ip] || Socket.ip_address_list[1].ip_address
      end

      def executable_exists?(exe)
        ENV['PATH'].split(':').map { |x| File.join(x, exe) }.find { |x| File.exist?(x) }
      end

      def download_clair
        File.join(Dir.tmpdir, 'clair-scanner').tap do |exe|
          Down.download(clair_download_url, destination: exe)
          `chmod +x #{exe}`
        end
      end

      def clair_download_url
        exe = EXECUTABLES["#{Gem::Platform.local.cpu}-#{Gem::Platform.local.os}"]
        return File.join(DOWNLOAD_PATH, options[:scanner_version], exe) if exe

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

      def clair_db_running?
        'docker ps --filter="name=clair-db" --filter="status=running" --filter="expose=5432/tcp" | grep -v CONT'
      end

      def clair_db
        'docker run -d --name clair-db --network=host arminc/clair-db:latest'
      end

      def clair_local_scan
        'docker run --restart=unless-stopped -p 6060:6060 --add-host=postgres:0.0.0.0 --network=host -d --name clair arminc/clair-local-scan:latest'
      end

      def clair_local_scan_running?
        'docker ps --filter="name=clair" --filter="status=running" --filter="expose=6060/tcp" | grep -v CONT'
      end

      def clair_local_scan_api_reachable?(url = options[:url])
        "curl -s #{url}/v1/namespaces > /dev/null"
      end
    end
  end
end
