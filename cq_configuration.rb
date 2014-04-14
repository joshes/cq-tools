require 'json'

module CqTools
  module Configuration

    # TODO refactor so these methods don't require incoming (already read) config
    # TODO refactor these method names

    def self.configured_host(config)
      server_index = config['server']
      server_config = config['servers'][server_index]
      is_secure = Common::to_bool server_config['secure']
      scheme = is_secure ? 'https' : 'http'
      "#{scheme}://#{server_config['host']}:#{server_config['port']}"
    end

    def self.configured_user(config)
      config['servers'][config['server'].to_i]['user']
    end

    def self.configured_build(config)
      workspace(config)['build']
    end

    def self.configured_pass(config)
      config['servers'][config['server']]['pass']
    end

    def self.workspace(config)
      config['workspaces'][config['workspace']]
    end

    def self.config_file_path
      File.join(File.expand_path('~'), '.cq/cfg')
    end

    def self.read_config
      JSON.parse(File.open(config_file_path, 'rb').read)
    end

    def self.save_config(config)
      File.open(config_file_path, 'wb').write(JSON.pretty_generate(config))
    end

  end
end