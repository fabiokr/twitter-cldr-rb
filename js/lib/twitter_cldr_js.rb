$:.push(File.dirname(__FILE__))

require 'yaml'
require 'mustache'
require 'uglifier'
require 'fileutils'
require 'jasmine-headless-webkit'
require 'coffee-script'

require 'compiler'
require 'renderers/bundle'
require 'renderers/calendars/datetime_renderer'

module TwitterCldr
  module Js
    def self.build(options = {})
      TwitterCldr::Js::Compiler.new(options).compile do |bundle, locale|
        cur_file = (options[:file_name] || "twitter_cldr_%{locale}.js").gsub("%{locale}", locale.to_s)

        if options[:minify]
          ext = File.extname(cur_file)
          min_file = "#{cur_file.chomp(File.extname(cur_file))}.min#{ext}"
          File.open(File.join(build_dir, min_file), "w+") do |f|
            f.write(Uglifier.compile(bundle))
          end
        else
          File.open(File.join(build_dir, cur_file), "w+") do |f|
            f.write(bundle)
          end
        end
      end
    end

    def self.clean(output_dir = build_dir)
      FileUtils.rm_rf(Dir.glob(File.join(build_dir, "**")))
    end

    def self.build_dir
      File.join(File.dirname(File.dirname(__FILE__)), "build")
    end

    def self.output_dir
      unless defined?(@@output_dir)
        @@output_dir = build_dir
      end
      @@output_dir
    end

    def self.output_dir=(new_dir)
      @@output_dir = new_dir
    end

    def self.make(options = {})
      # clean dir, then build js
      FileUtils.rm_rf(Dir.glob(File.join(build_dir, "**")))
      build(options)
      build(options.merge({ :minify => true }))
    end

    def self.test
      Dir.chdir(File.dirname(__FILE__)) do
        Jasmine::Headless::Runner.run(:colors => true, :jasmine_config => File.expand_path("../spec/support/jasmine.yml"))
      end
    end

    def self.install
      FileUtils.mkdir_p(output_dir)
      Dir.glob(File.join(build_dir, "**/**")).each do |source_file|
        if File.file?(source_file)
          dest_file = File.join(output_dir, source_file.gsub(build_dir, ""))
          FileUtils.cp(source_file, dest_file)
        end
      end
    end
  end
end