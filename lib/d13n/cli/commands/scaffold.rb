require 'fileutils'
require 'erb'
require 'd13n/version'
module D13n::Cli
  class Scaffold < Command
    def self.command; "scaffold"; end

    attr_accessor :application, :project, :ruby_version, :application_base

    def initialize(args)
      @bare = false
      @application = nil
      @ruby_version = '2.3.1'
      super(args)
    end

    def run
      check_options
      generate_scaffold
    end

    def check_options
      if @application.nil?
        puts 'application name required'
        exit 1
      elsif @project.nil?
        puts 'project name required'
        exit 1
      end
    end

    def generate_scaffold
      @template_home = File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', '..', '..', 'templates')

      unless @bare
        puts "Setting up application [#{application_base}] directories..."
        Dir.mkdir(@application) unless File.directory?(@application)
        Dir.chdir(@application)
      end

      @current_home = Dir.pwd

      unless @bare
        application_scaffold
      end

      rake_scaffold

      migration_scaffold

      gem_scaffold

      makefile_scaffold

      application_yml_scaffold

      docker_scaffold

      docker_script_scaffold

      jekinsfile_scaffold

      ruby_version_scaffold

      spec_scaffold
        
    end

    private

    def application_base
     @application_base = @application.split('_').map {|w| w.capitalize}.join
    end

    def application_const
      @application_const ||= "#{application_base}::Service"
    end

    def template_erb(src, dst, src_sub_path=nil, dst_sub_path=nil)
      src_file = if src_sub_path.nil?
        File.join(@template_home,src)
      else
        File.join(@template_home, src_sub_path, src)
      end
      dst_file = if dst_sub_path.nil?
        File.join(@current_home,dst)
      else
        File.join(@current_home, dst_sub_path, dst)
      end
      File.open(src_file) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(dst_file, 'w') do |ofh|
          ofh.print erb.result(binding)
        end
      end
    end

    def application_scaffold
      puts "Generating application[#{application_base}] lib folder ..."
      Dir.mkdir('lib')
      application_source_path = File.join("lib","#{application}")
      Dir.mkdir(application_source_path)

      puts "Generating #{application_base} namespace file ..." 
      template_erb('application.rb.template', "#{application}.rb", 'lib', 'lib')

      puts "Generating #{application_base} service file ..."
      template_erb('service.rb.template','service.rb','lib',application_source_path)
      template_erb('version.rb.template','version.rb','lib',application_source_path)

      application_api

      application_rack
    end

    def application_api
      puts "Generating application[#{application_base}] api folder ..."
      api_root = File.join('lib',application,'api')
      Dir.mkdir(api_root)

      api_template_root = File.join('lib', 'api')
      puts api_template_root
      puts "Generating #{application_base} api files ..."
      template_erb('service.rb.template','service.rb',api_template_root, api_root)
      template_erb('support.rb.template','support.rb',api_template_root, api_root)
      template_erb('version.rb.template','version.rb',api_template_root, api_root) 
    end

    def application_rack
      puts "Generating application[#{application_base}] rack file ..."
      template_erb('config.ru.template','config.ru')
    end

    def migration_scaffold
      puts "Generating database migration folders ..."
      @migration_root = 'db'
      Dir.mkdir(@migration_root) unless File.directory?(@migration_root)

      @migration_sub_dir = ['migrations', 'seeds']
      @migration_sub_dir.each do |dir|
        root_dir = "#{@migration_root}/#{dir}"
        Dir.mkdir(root_dir) unless File.directory?(root_dir)
      end

      puts "Generating Rake migration file ..."

      File.open(File.join(@template_home, @rake_task_root, 'migration.rake.template')) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(File.join(@current_home, @rake_task_root, "migration.rake"), 'w') do |ofh|
          ofh.print erb.result(binding)
        end
      end
    end

    def gem_scaffold
      puts "Generating Gemfile ..."

      File.open(File.join(@template_home, 'Gemfile.template')) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(File.join(@current_home, "Gemfile"), 'w') do |ofh|
          ofh.print erb.result(binding)
        end
      end
    end
    
    def makefile_scaffold
      puts "Generating Makefile ..."
      File.open(File.join(@template_home, 'Makefile.template')) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(File.join(@current_home, "Makefile"), 'w') do |ofh|
          ofh.print erb.result(binding)
        end
      end
    end

    def application_yml_scaffold
      puts "Generating #{@application}.yml ..."
      File.open(File.join(@template_home, 'application.yml.template')) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(File.join(@current_home, "#{@application}.yml"), 'w') do |ofh|
          ofh.print erb.result(binding)
        end
      end
    end

    def docker_scaffold
      puts "Generating docker folder ..."
      @docker_root = 'docker'
      Dir.mkdir(@docker_root) unless File.directory?(@docker_root)

      @docker_development_files = ['docker-compose.yml','Dockerfile.cache','Dockerfile']
      @docker_release_files = ['docker-compose.yml', 'Dockerfile']

      docker_stage(@docker_root, 'development', @docker_development_files)
      docker_stage(@docker_root, 'release', @docker_release_files)
    end

    def docker_stage(root, stage, files)
      puts "Generating docker #{stage} folder ..."
      root_dir = "#{root}/#{stage}"
      Dir.mkdir(root_dir) unless File.directory?(root_dir)

      puts "Generating #{stage} docker files ..."
      stage_dir = "#{root}/#{stage}"
      files.each do |file|
        File.open(File.join(@template_home, "docker", "#{file}.#{stage}")) do |tfh|
          erb = ERB.new(tfh.read)
          File.open(File.join(@current_home, stage_dir, file), 'w') do |ofh|
            ofh.print erb.result(binding)
          end
        end
      end
    end

    def docker_script_scaffold
      @docker_script_root = 'scripts'
      Dir.mkdir(@docker_script_root) unless File.directory?(@docker_script_root)

      puts "Generating docker scripts ..."
      File.open(File.join(@template_home, "#{@docker_script_root}/", "test.sh.template")) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(File.join(@current_home, "#{@docker_script_root}/", "test.sh"), 'w') do |ofh|
          ofh.print erb.result(binding)
        end

        FileUtils.chmod 0755,File.join(@current_home, "#{@docker_script_root}/", "test.sh")
      end
    end

    def jekinsfile_scaffold
      puts "Generating Jekinsfile ..."

      File.open(File.join(@template_home, "Jenkinsfile.template")) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(File.join(@current_home, "Jenkinsfile"), 'w') do |ofh|
          ofh.print erb.result(binding)
        end
      end
    end

    def ruby_version_scaffold
      puts "Generating Ruby Version file ..."

      File.open(File.join(@template_home, ".ruby-version.template")) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(File.join(@current_home, ".ruby-version"), 'w') do |ofh|
          ofh.print erb.result(binding)
        end
      end
    end

    def spec_scaffold
      puts "Generating RSpec configuraion file ..."

      File.open(File.join(@template_home, ".rspec.template")) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(File.join(@current_home, ".rspec"), 'w') do |ofh|
          ofh.print erb.result(binding)
        end
      end

      puts "Generating Spec folders ..."

      @spec_root = 'spec'

      Dir.mkdir(@spec_root) unless File.directory?(@spec_root)

      ['unit', 'functional', 'factories'].each do |folder|
        spec_sub_dir = File.join(@spec_root, folder)
        Dir.mkdir(spec_sub_dir) unless File.directory?(spec_sub_dir)
      end

      puts "Generating Rspec Helper file ..."

      File.open(File.join(@template_home, "spec", "spec_helper.rb.template")) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(File.join(@current_home, "spec", "spec_helper.rb"), 'w') do |ofh|
          ofh.print erb.result(binding)
        end
      end

      puts 'Generating Rspec rake task file ...'

      File.open(File.join(@template_home, @rake_task_root, "spec.rake.template")) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(File.join(@current_home, @rake_task_root, "spec.rake"), 'w') do |ofh|
          ofh.print erb.result(binding)
        end
      end
    end

    def rake_scaffold
      puts "Generating Rake file ..."

      File.open(File.join(@template_home, "Rakefile.template")) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(File.join(@current_home, "Rakefile"), 'w') do |ofh|
          ofh.print erb.result(binding)
        end
      end

      puts "Generating Rake Task folder ..."

      @rake_task_root = 'tasks'

      Dir.mkdir(@rake_task_root) unless File.directory?(@rake_task_root)
    end

    def options
      OptionParser.new %Q{Usage: #{$0} #{self.class.command} [OPTIONS] ["description"] }, 40 do |opts|
        opts.separator ''
        opts.separator 'Specific options:'

        opts.on('-a APP', '--app','Specify an application to scaffold') do |app|
          @application = app.downcase
        end

        opts.on('-p PROJECT', '--project','Specify project of application to scaffold') do |project|
          @project = project.downcase
        end

        opts.on('-b', '--bare', 'Scaffold a bare folder') do |bare|
          @bare = true
        end
      end
    end
  end
end