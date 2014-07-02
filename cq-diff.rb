#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'uri'
require 'net/http'
require 'openssl'

module Cq

  class Package
    attr_reader :name, :version

    def initialize(name, version='')
      @name = name
      @version = version
    end

    def to_s
      s_version = @version.eql?('') ? '' : ":#{@version}"
      "#{@name}#{s_version}"
    end
  end

  class PackageDiffer

    @@DEBUG = false

    def ls(uri)
      do_proxy = false
      proxy_host = do_proxy ? 'localhost' : nil
      proxy_port = do_proxy ? '8888' : nil
      Net::HTTP.new(uri.host, uri.port, proxy_host, proxy_port).start { |http|
        if @@DEBUG
          request = Net::HTTP::Get.new(uri.path)
        else
          request = Net::HTTP::Get.new('/crx/packmgr/service.jsp?cmd=ls')
        end
        request.basic_auth(uri.user, uri.password)
        http.use_ssl = uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        response = Nokogiri::XML(http.request(request).body)
        response.xpath('//package').map { |package|
          name = (package > 'name/text()').text
          version = (package > 'version/text()').text
          Package.new(name, version)
        }
      }
    end

    def initialize(lhs_uri, rhs_uri)

      matches = []
      fails = []
      lhs = ls(lhs_uri)
      rhs = ls(rhs_uri)

      lhs.each { |l|

        found = false
        exact_match = false
        version_mismatch = false
        rhs_version = nil

        # Find matches, version mismatches and missing packages from l -> r
        rhs.each { |r|
          if l.name.eql? r.name
            found = true
            if l.version.eql? r.version
              # exact match
              exact_match = true
            else
              # version mismatch
              rhs_version = r.version
              version_mismatch = true
            end
          else
            # not found
          end
        }

        matches.push(l.to_s) if exact_match
        fails.push("#{l.to_s} != #{rhs_version}") if version_mismatch
        fails.push("#{l.to_s} ! missing from #{rhs_uri.host}") if not found
      }

      # Find missing packages from r -> l
      rhs.each { |r|
        found = false
        lhs.each { |l|
          if r.name.eql? l.name
            # not found
            found = true
          end
        }
        fails.push("#{r.to_s} ! missing from #{lhs_uri.host}") if not found
      }

      # Sort for sanity
      matches.sort!
      fails.sort!

      # Just print fails for now
      if fails.length > 0
        fails.each {|m| puts m }
      else
        puts 'No differences found'
      end
    end

  end
end

Cq::PackageDiffer.new(URI(ARGV[0]), URI(ARGV[1]))
