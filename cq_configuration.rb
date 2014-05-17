require 'json'

module Cq

  class Server
    attr_reader :id, :path, :host, :port, :user, :pass, :secure, :scheme, :url

    def initialize(server_json)
      @json = server_json
      @id = server_json['id']
      @path = server_json['path']
      @host = server_json['host']
      @port = server_json['port']
      @user = server_json['user']
      @pass = server_json['pass']
      @secure = server_json['secure'].eql? 'true'
      @scheme = @secure ? 'https' : 'http'
      @url = "#{@scheme}://#{@host}:#{@port}"
    end

    def is_secure?
      @secure
    end
  end

  class CleanConfiguration
    attr_reader :nodes, :bundles

    def initialize(clean_json)
      @json = clean_json
      @nodes = clean_json['nodes']
      @bundles = clean_json['bundles']
    end
  end

  class BuildProject
    attr_reader :id, :profiles, :path

    def initialize(project_json)
      @json = project_json
      @id = project_json['id']
      @profiles = project_json['profiles']
      @path = project_json['path']
    end
  end

  class BuildGroup
    attr_reader :id, :projects

    def initialize(groups_json)
      @json = groups_json
      @id = groups_json['id']
      @projects = groups_json['projects']
    end
  end

  class BuildConfig
    attr_reader :global_profiles, :skip_test_flags, :projects, :groups

    def initialize(build_json)
      @json = build_json
      @global_profiles = build_json['profiles']
      @skip_test_flags = build_json['skipTestFlags']
      @projects = build_json['projects'].map { |project_json| Cq::BuildProject.new project_json }
      @groups = build_json['groups'].map { |groups_json| Cq::BuildGroup.new groups_json }
    end
  end

  class ProjectConfig
    attr_reader :clean_config, :build_config

    def initialize(config_file)
      @json = JSON.parse(File.open(config_file, 'rb').read)
      @clean_config = Cq::CleanConfiguration.new @json['clean']
      @build_config = Cq::BuildConfig.new @json['build']
    end
  end

  class Project
    attr_reader :id, :path, :config

    def initialize(project_json)
      @json = project_json
      @id = project_json['id']
      @path = project_json['path']
      @config_path = File.join Cq::Common::config_dir, project_json['config']
      @config = Cq::ProjectConfig.new File.expand_path @config_path
    end
  end

  class ConfigurationReader
    attr_reader :server, :servers, :project, :projects, :debug

    def initialize
      @path = Cq::Common::config_file
      @json = JSON.parse(File.open(@path, 'rb').read)
      @server = @json['server']
      @project = @json['project']
      @servers = @json['servers'].map { |server_json| Cq::Server.new server_json }
      @projects = @json['projects'].map { |project_json| Cq::Project.new project_json }
      @debug = @json['debug'].eql? 'true'
    end

    def is_debug?
      @debug
    end

    def active_project
      @projects[@project]
    end

    def active_server
      @servers[@server]
    end

    def save!
      File.open(@path, 'wb').write(JSON.pretty_generate(@json).to_s)
    end

    def set_active_project(index)
      @json['project'] = index if index >= 0 and index < @json['projects'].length
    end

    def set_active_server(index)
      @json['server'] = index if index >= 0 and index < @json['servers'].length
    end

  end
end