module CqTools
  module Common

    # Returns the argument value from argv if found (format: --key=value) or default if not found
    def self.arg_else(argv, key, default)
      v = argv.select { |k| k.start_with? key }
      v.length > 0 ? v[0].split("#{key}=")[1] : default
    end

    # Checks if the argument key is set (regardless of value being set with format: --key)
    def self.arg_set?(argv, key)
      v = argv.select { |k| k.start_with? key }
      v.length > 0
    end

    def self.user_home_dir
      File.expand_path '~'
    end

    def self.env_file
      File.join(user_home_dir, '.cq/env')
    end

    def self.usr_file
      File.join(user_home_dir, '.cq/cfg')
    end

    def self.to_bool(s)
      s == 'true' || s == '1'
    end
    
  end
end