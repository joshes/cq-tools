# Returns the argument value from argv if found (format: --key=value) or default if not found
def arg_else(argv, key, default)
  v = argv.select { |k| k.start_with? key }
  v.length > 0 ? v[0].split("#{key}=")[1] : default
end

# Checks if the argument key is set (regardless of value being set with format: --key)
def arg_set?(argv, key)
  v = argv.select { |k| k.start_with? key }
  v.length > 0
end

def user_home_dir
  File.expand_path '~'
end

def env_file
  File.join(user_home_dir, '.cq/env')
end

def usr_file
  File.join(user_home_dir, '.cq/cfg')
end

def read_config!
  JSON.parse(File.open(usr_file, 'rb').read)
end

def save_config!(config)
  File.open(usr_file, 'wb').write(JSON.pretty_generate(config))
end

def to_bool(s)
  s.downcase == 'true' || s == '1'
end

def configured_host(config)
  server_index = config['server']
  server_config = config['servers'][server_index]
  is_secure = to_bool server_config['secure']
  scheme = is_secure ? 'https' : 'http'
  "#{scheme}://#{server_config['host']}:#{server_config['port']}"
end

def configured_user(config)
  config['server']['user']
end

def configured_pass(config)
  config['server']['pass']
end

def workspace(config)
  config['workspaces'][config['workspace']]
end

