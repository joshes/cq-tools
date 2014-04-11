require 'rubygems'
require 'json'
require_relative 'cq-common'

def read_config!
  JSON.parse(File.open(usr_file, 'rb').read)
end

def save_config!(config)
  File.open(usr_file, 'wb').write(JSON.pretty_generate(config))
end

def list_options(array_with_ids)
  array_with_ids.each_with_index do |entry, i|
    puts "  #{i}: #{entry['id']}"
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

def write_env(env_key, val)
  puts "#{env_key}=#{val} "
  file_reader = File.open(env_file, 'rb')
  contents = file_reader.read
  file_reader.close
  contents.gsub!(/^export #{env_key}=.*$/, "export #{env_key}=#{val}")
  file_writer = File.open(env_file, 'wb')
  file_writer.write(contents)
  file_writer.close
end

def exec_switch(key_single, key_multi)
  config = read_config!
  things = config[key_multi]
  if things.length == 1
    puts "Only one #{key_single} available - nothing to switch to"
    puts "To add a new #{key_single} configuration modify: #{usr_file}"
    exit 0
  end
  default_option = config[key_single]
  selected = switch(key_single, key_multi, things, default_option)
  config[key_single] = selected
  save_config! config
  yield config[key_multi][selected] if block_given?
end