=begin
Copyright 2016 Eric Agnew eric@bradsdeals.com

See the file LICENSE for copying permission.
=end

require 'pre-commit/error_list'
require 'pre-commit/checks/plugin'
require "pre-commit/configuration/top_level"
require 'mkmf'
require 'find'

module PreCommit
  module Checks
    class Jscs < Shell
      include PreCommit::Configuration::TopLevel

      def node_modules_bin
        @node_modules ||= File.join(self.top_level, 'node_modules', '.bin')
      end

      # First look for jscs in the top_level
      def app_source
        return @app_source if @app_source

        Find.find(node_modules_bin) {|path| @app_source = path if path =~ /jscs$/ }
        @app_source
      end

      # If jscs is not in the top_level see if its defined within the system
      def sys_source
        @sys_source ||= MakeMakefile.find_executable("jscs")
      end

      def self.description
        "Support for jscs linting"
      end

      def call(staged_files)
        return "JSCS executable could not be located" if app_source.nil? && sys_source.nil?
        staged_files = staged_files.grep(/\.js$/)
        return if staged_files.empty?

        result =
        in_groups(staged_files).map do |files|
          args = [(app_source || sys_source)] + files
          execute(args)
        end.compact

        result.empty? ? nil : result.join("\n")
      end

      def config_file_flag
        config_file ? ['--preset', config_file] : []
      end

    end
  end
end
