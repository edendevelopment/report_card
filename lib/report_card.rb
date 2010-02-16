$:.unshift(File.dirname(__FILE__))

require 'metric_fu'
require 'tinder'
require 'erb'
require 'report_card/index'
require 'report_card/grader'

module ReportCard
  CONFIG_FILE = File.expand_path(File.join(File.dirname(__FILE__), "..", "config.yml"))

  def self.grade
    Integrity.new(config['integrity_config'])
    self.setup

    ignore = config['ignore'] ? Regexp.new(config['ignore']) : /[^\w\d\s\S]+/
    projects = []

    Integrity::Project.all.each do |project|
      if project.name !~ ignore
        grader = Grader.new(project, config)
        grader.grade
        projects << project if grader.success?
      end
    end

    Index.create(projects, config['site']) unless projects.empty?
  end

  def self.config
    if File.exist?(CONFIG_FILE)
      @config ||= YAML.load_file(CONFIG_FILE)
      #require_integrity_path
      @config
    else
      Kernel.abort("You need a config file at #{CONFIG_FILE}. Check the readme please!")
    end
  end

  def self.require_integrity_path
    require File.expand_path(File.join(File.dirname(@config['integrity_config']), "..", "lib", "integrity"))
  end

  def self.setup
    FileUtils.mkdir_p(config['site'])
    FileUtils.cp(Dir[File.join(File.dirname(__FILE__), '..', 'template', '*.{css,ico}')], config['site'])
  end
end
