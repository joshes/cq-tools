require_relative 'cq_common'
require_relative 'cq_configuration'

module CqTools
	module Build

		include CqTools::Common
		include CqTools::Configuration

		def self.build_project(workspace_path, proj_config, profiles, clean, test, offline, skip_test_flags)
			proj_id = proj_config['id']
			proj_path = proj_config['path']
			project = File.join(workspace_path, proj_path.nil? ? proj_id : proj_path)
			str_profiles = profiles.length == 0 ? '' : " -P #{profiles.join(',')} "
			str_clean = clean ? ' --clean ' : ''
			str_test = test ? skip_test_flags.join(' ') : ''
			str_offline = offline ? ' --offline ' : ''
			puts "mvn #{project} #{str_clean}#{str_profiles}#{str_test}#{str_offline}"
		end

		def self.maven_exec(argv)

			# Read args
			clean = arg_set? argv, '-c'
			test = arg_set? argv, '-t'
			offline = arg_set? argv, '-o'
			requested_id = argv.last # TODO validate this - not necessarily set

			# Read configuration
			config = read_config
			build_config = configured_build(config)
			workspace_config = workspace(config)
			profiles = build_config['profiles']
			skip_test_flags = build_config['skipTestFlags']
			projects = build_config['projects']
			groups = build_config['groups']

			# Find the group/project configuration based on incoming project name, groups get priority
			projects_to_build = []
			group_config = groups.select { |c| c['id'] == requested_id }
			if group_config.length > 0
				project_ids = group_config['projects']
				projects_to_build = projects.select { |p| project_ids.include? p['id'] }
			else
				projects_to_build = projects.select { |c| c['id'] == requested_id }
			end

			# Only build each once
			projects_to_build.uniq!

			# Build 
      projects_to_build.each { |proj_config|
				build_project(workspace_config['path'], proj_config, profiles, clean, test, offline, skip_test_flags)
			}
		end

	end
end

CqTools::Build::maven_exec(ARGV)
