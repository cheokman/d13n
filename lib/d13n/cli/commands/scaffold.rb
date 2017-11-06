require 'fileutils'
require 'erb'
module D13n::Cli
  class Scaffold < Command
    def self.command; "scaffold"; end

    attr_accessor :application, :project

    def initialize(args)
      @bare = false
      @application = nil
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
        puts "Setting up appication [#{application_base}] directories..."
        Dir.mkdir(@application) unless File.directory?(@application)
        Dir.chdir(@application)
      end

      @current_home = Dir.pwd

      migration_scaffold

      makefile_scaffold

      application_yaml_scaffold

      docker_scaffold

      docker_script_scaffold

      jekinsfile_scaffold
        
    end

    private

    def application_base
     @application_base = @application.split('_').map {|w| w.capitalize}.join
    end

    def application_const
      @application_const ||= "#{application_base}::Application"
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

    def application_yaml_scaffold
      puts "Generating #{@application}.yaml ..."
      File.open(File.join(@template_home, 'application.yaml.template')) do |tfh|
        erb = ERB.new(tfh.read)
        File.open(File.join(@current_home, "#{@application}.yaml"), 'w') do |ofh|
          ofh.print erb.result(binding)
        end
      end
    end

    def docker_scaffold
      puts "Generating docker folder ..."
      @docker_root = 'docker'
      Dir.mkdir(@docker_root) unless File.directory?(@docker_root)

      @docker_development_files = ['docker-compose.yaml','Dockerfile.cache','Dockerfile']
      @docker_release_files = ['docker-compose.yaml', 'Dockerfile']

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
        File.open(File.join(@template_home, "docker/" "#{file}.#{stage}")) do |tfh|
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