# frozen_string_literal: true

module Examine
  module CLI
    # Entrypoint to the CLI.
    class Application < Thor
      package_name 'examine'

      desc 'clair', 'manage clair'
      subcommand :clair, Examine::CLI::Clair
    end
  end
end
