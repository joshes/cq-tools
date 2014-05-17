require_relative 'cq_common'
require_relative 'cq_configuration'

module Cq

  class EnvironmentWriter

    def write(config_reader)
      file_writer = File.open(Common::env_file, 'wb')
      contents = []
      contents.push "export CQ_TOOLS_SERVER=#{config_reader.active_server.path}"
      contents.push "export CQ_TOOLS_PROJECT=#{config_reader.active_project.path}"
      file_writer.write(contents.join("\n"))
      file_writer.close
    end

  end

  class ConfigurationTool

    def switch_project
      config = ConfigurationReader.new
      selected = ConfigurationTool.new.switch('project', 'projects', config.projects, config.project)
      config.set_active_project selected
      config.save!
      EnvironmentWriter.new.write config
      reload
    end

    def switch_server
      config = ConfigurationReader.new
      selected = ConfigurationTool.new.switch('server', 'servers', config.servers, config.server)
      config.set_active_server selected
      config.save!
      EnvironmentWriter.new.write config
      reload
    end

    protected

    def reload
      puts "Ensure you run: 'source #{Common::env_file}' in any open terminals for changes to take effect."
    end

    def list_options(array_with_ids)
      array_with_ids.each_with_index do |entry, i|
        puts "  #{i}: #{entry.id}"
      end
    end

    def select(key_single, default_option)
      puts "Please select #{key_single} to use [#{default_option}]:"
      selected = STDIN.gets
      if selected.nil?
        selected = default_option
      else
        selected = selected.to_i
      end
      selected
    end

    def switch(key_single, key_multi, things, default_option)
      puts "Available #{key_multi}:"
      list_options(things)
      selected = select(key_single, default_option)
      while selected < 0 or selected > (things.length - 1)
        puts "Invalid selection please select: (0 - #{things.length - 1})"
        selected = select(key_single, 0)
      end
      selected
    end

  end
end

err = 'Invalid arguments - expected: server | project'
if ARGV.length == 0
  puts err
  exit 1
end

if ARGV[0].eql? 'server'
  Cq::ConfigurationTool.new.switch_server
elsif ARGV[0].eql? 'project'
  Cq::ConfigurationTool.new.switch_project
else
  puts err
  exit 1
end
