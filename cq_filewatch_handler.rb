#!/usr/bin/env ruby

#
# Working man's content sync-up support for CQ5.
#
# Installation (until bundler support is added):
# sudo gem install activesupport json nokogiri
#
# Future work:
# - Add support for file deletion
# - Add more file types as necessary
# - Create a generic contract for file watchers to pass to this handler
#
# Author: Joshua Hansen

require 'rubygems'
require 'pathname'
require 'open-uri'
require 'active_support/core_ext'
require 'json'
require 'nokogiri'
require_relative 'cq_common'
require_relative 'cq_configuration'

module Cq
  module FileWatchHandler

    DEBUG = false
    RAISE_ERRORS = false

    def self.usage
      puts 'USAGE:'
      puts '--file="$FilePath$" (Required)'
      puts '--user=admin        (Optional - default shown)'
      puts '--pass=admin        (Optional - default shown)'
      puts '--host=localhost    (Optional - default shown)'
      puts '--port=4502         (Optional - default shown)'
      puts '--secure            (Optional - switches to https:// - not enabled by default)'
    end

    def self.curl_verbosity
      DEBUG ? '-v' : '-s'
    end

    def self.curl_referer
      '-H "referer: app:/"'
    end

    # Upload an arbitrary file to the JCR
    def self.upload_file(ctx)
      cmd = %Q[curl #{curl_verbosity} #{curl_referer} -u #{ctx[:user]}:#{ctx[:pass]} -F"#{ctx[:filename]}=@#{ctx[:file]}" #{ctx[:url]}#{ctx[:jcr_path].dirname}]
      puts cmd if DEBUG
      `#{cmd}`
    end

    # Set the mime type attribute on an existing file in the JCR
    def self.set_mime(ctx)
      cmd = %Q[curl #{curl_verbosity} #{curl_referer} -u #{ctx[:user]}:#{ctx[:pass]} -F"jcr:mimeType=#{ctx[:mime_type]}" #{ctx[:url]}#{ctx[:jcr_path]}/jcr:content]
      puts cmd if DEBUG
      `#{cmd}`
    end

    # Posts a JCR node replacing it entirely, unless its a property only node in
    # which case those properties will be updated only
    def self.post_node(ctx)

      replace = true
      replace_props = true
      filename = ctx[:filename_no_extension]
      jcr_path = File.expand_path(ctx[:jcr_path] + '..')

      if ctx[:filename] =~ /^\.content\.xml$/
        filename = ctx[:jcr_path].dirname.to_s.split('/').last
        jcr_path = File.expand_path(jcr_path + '/..')
        replace = false
        replace_props = true
      end

      # I now understand why these files are named so: _cq_ -> cq: ... it breaks the xmlns rules in the xml!
      [filename, jcr_path].each { |s| s.gsub!(/_cq_/, 'cq:') }

      # XML posting doesn't appear to be working !
      # Attempted with contentType=jcr.xml with XML data entities encoded ... until then this is a valid workaround:

      xml = Nokogiri::XML(File.open(ctx[:file]).read)
      xml = xml.root.to_s
      xml_hash = Hash.from_xml(xml)
      # rename root node & remove namespace support
      ns_key = xml_hash.keys[0]
      xml_hash[filename] = xml_hash[ns_key].delete_if { |k, v| k =~ /^xmlns:.*/ }
      xml_hash.delete(ns_key)

      # xml to json
      json = xml_hash.to_json.to_s

      # fix array entries that are wrapped in double quotes
      json = json.gsub(/"\[(.*?)\]"/) { |match|
        content = $1.split(',').map { |item| "\"#{item}\"" }.join(',')
        "[#{content}]"
      }

      # convert "_" back to "-" ... this may kill us at some point
      json = json.gsub(/_/, '-')

      # escape double-quotes
      json = json.gsub(/"/, '\"')

      cmd = %Q[curl #{curl_verbosity} #{curl_referer} -u #{ctx[:user]}:#{ctx[:pass]} -F":operation=import" -F":contentType=json" -F":replace=#{replace}" -F":replaceProperties=#{replace_props}" -F":content=#{json}" #{ctx[:url]}#{jcr_path}]
      puts cmd if DEBUG
      `#{cmd}`
    end

    # Route keys map to handler keys ...
    def self.routes
      {
          :file => [
              {
                  :mime_type => 'text/plain',
                  :matchers => %w(.jsp .css js.txt css.txt)
              },
              {
                  :mime_type => 'application/javascript',
                  :matchers => ['.js']
              },
              {
                  :mime_type => 'image/png',
                  :matchers => ['.png']
              },
              {
                  :mime_type => 'image/jpeg',
                  :matchers => %w(.jpg .jpeg)
              }],
          :node => [
              {
                  :mime_type => nil,
                  :matchers => ['.xml']
              }]
      }
    end

    # Handler keys point to an array of methods to execute against the context supplied
    def self.handlers
      {
          :file => [method(:upload_file), method(:set_mime)],
          :node => [method(:post_node)]
      }
    end

    # Builds up the handler context and some conveniences
    def self.build_context(argv)
      ctx = {
          :file => Common::arg_else(argv, '--file', nil),
          :user => Common::arg_else(argv, '--user', 'admin'),
          :pass => Common::arg_else(argv, '--pass', 'admin'),
          :host => Common::arg_else(argv, '--host', 'localhost'),
          :port => Common::arg_else(argv, '--port', '4502'),
          :protocol => Common::arg_set?(argv, '--secure') ? 'https' : 'http',
      }
      ctx[:url] = "#{ctx[:protocol]}://#{ctx[:host]}:#{ctx[:port]}"
      ctx[:jcr_path] = Pathname.new(ctx[:file].split('jcr_root')[1])
      ctx[:file_extension] = File.extname(ctx[:file])
      ctx[:routes] = routes
      ctx[:handlers] = handlers
      ctx[:filename] = ctx[:jcr_path].basename.to_s
      ctx[:filename_no_extension] = ctx[:filename].chomp(ctx[:file_extension])
      ctx
    end

    def self.priority_matchers
      # FCFS - order matters!
      [
          # Filename matcher
          Proc.new { |matchers, ctx|
            res = matchers.include?(ctx[:jcr_path].basename.to_s)
            puts "Matchers include #{ctx[:jcr_path].basename} = #{res}" if DEBUG
            res
          },
          # Extension matcher
          Proc.new { |matchers, ctx|
            res = matchers.include?(ctx[:file_extension].to_s)
            puts "Matchers include #{ctx[:file_extension]} = #{res}" if DEBUG
            res
          }
      ]
    end

    # Given a valid context, will attempt to find handlers to run against the context
    def self.handle(ctx)
      priority_matchers.each { |match_check|
        ctx[:routes].each { |route_type, route_info_arr|
          route_info_arr.each { |route_info|
            matchers = route_info[:matchers]
            puts "Matchers=#{matchers}" if DEBUG
            if match_check.call(matchers, ctx)
              puts "#{Time.now} #{ctx[:jcr_path]}"
              ctx[:mime_type] = route_info[:mime_type]
              ctx[:handlers][route_type].each { |handler|
                handler.call(ctx)
              }
            end
          }
        }
      }
    end

  end
end

# Guards
supplied_file = Cq::Common::arg_else(ARGV, '--file', nil)
if supplied_file.nil?
  Cq::FileWatchHandler::usage
  exit(1)
end

raise 'File is not valid jcr_root path!' if supplied_file !~ /.*\/?jcr_root\/.*/ and RAISE_ERRORS

# Entry-point
ctx = Cq::FileWatchHandler::build_context(ARGV)
Cq::FileWatchHandler::handle(ctx)