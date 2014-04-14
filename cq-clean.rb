#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'open-uri'
require_relative 'cq_common'
require_relative 'cq_configuration'

module CqTools
  module Clean

    # Get all keys from hash recursively
    def self.nested_keys(hash)
      keys = []
      hash.keys.each { |key|
        if hash[key].is_a? Hash
          keys += nested_keys(hash[key])
        end
        keys << key
      }
      keys
    end

    def self.get_bundles(str_json, bundle_patterns)
      json = JSON.parse(str_json)
      nested_keys(json).uniq.select { |k|
        matches = bundle_patterns.select { |p|
          k =~ p
        }
        matches.length > 0
      }
    end

    def self.exec

      # TODO wrap the configuration into an object ...

      config = Configuration::read_config
      verbose = Common::to_bool(config['debug'])
      host = Configuration::configured_host(config)
      user = Configuration::configured_user(config)
      pass = Configuration::configured_pass(config)
      workspace = Configuration::workspace(config)
      clean_opts = workspace['clean']
      nodes = clean_opts['nodes']
      bundle_patterns = clean_opts['bundles'].map { |pattern| /#{pattern}/ }

      p bundle_patterns

      # Find packages to remove based on bundle patterns
      bundles = []
      begin
        str_json = open("#{host}/etc/packages.infinity.json", :http_basic_authentication => [user, pass]).read
        bundles = get_bundles(str_json, bundle_patterns)
      rescue OpenURI::HTTPError => error
        response = error.io
        if response.status[0].to_i == 300
          # CQ 5.6 changes how they use infinity selector - find the deepest path and use it
          path = JSON.parse(response.string).first
          str_json = open("#{host}/#{path}", :http_basic_authentication => [user, pass]).read
          bundles += get_bundles(str_json, bundle_patterns)
        else
          raise error, "Failed to get bundle list", caller
        end
      end

      bundles.uniq!

      puts '=-=-=-=-=-=-=-=-=-=-=-=-=-=-='
      puts 'Nodes to delete:'
      puts '=-=-=-=-=-=-=-=-=-=-=-=-=-=-='
      puts nodes
      puts ''
      puts '=-=-=-=-=-=-=-=-=-=-=-=-=-=-='
      puts 'Bundles to delete:'
      puts '=-=-=-=-=-=-=-=-=-=-=-=-=-=-='
      puts bundles
      puts ''
      puts 'Continue (y/n)?'

      yn = gets.chomp
      if yn !~ /[y|yes]/i
        puts 'Quiting'
        exit
      end

      v = ''
      if verbose
        v = '-v'
      end

      # Remove the packages
      commands = %w(uninstall delete)
      bundles.each { |bundle|
        commands.each { |cmd|
          `curl #{v} -X POST -H 'referer: app:/' -u #{user}:#{pass} -F cmd=#{cmd} #{host}/crx/packmgr/service/script.html/etc/packages/#{bundle}`
        }
      }

      # Remove the nodes
      nodes.each { |path|
        `curl #{v} -H 'referer: app:/' -F":operation=delete" #{host}#{path} -u #{user}:#{pass}`
      }

      puts 'Done'
    end

  end
end

CqTools::Clean::exec
