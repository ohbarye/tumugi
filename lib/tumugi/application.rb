require 'tumugi/dag'
require 'tumugi/dsl'
require 'tumugi/plugin'
require 'tumugi/target'
require 'tumugi/command/run'
require 'tumugi/command/show'

module Tumugi
  class Application
    attr_accessor :params

    def initialize
      @tasks = {}
      @params = {}
    end

    def execute(command, root_task_id, options)
      process_common_options(options)
      load(options[:file], true)
      dag = create_dag(root_task_id)
      command_module = Kernel.const_get("Tumugi").const_get("Command")
      cmd = command_module.const_get("#{command.to_s.capitalize}").new
      cmd.execute(dag, options)
    end

    def add_task(id, task)
      @tasks[id.to_s] = task
    end

    def find_task(id)
      task = @tasks[id.to_s]
      raise "Task not found: #{id}" if task.nil?
      task
    end

    private

    def create_dag(id)
      dag = Tumugi::DAG.new
      task = find_task(id)
      dag.add_task(task)
      dag
    end

    def process_common_options(options)
      init_logger(options)
      load_config(options)
      set_params(options)
    end

    def logger
      @logger ||= Tumugi.logger
    end

    def init_logger(options)
      logger.verbose! if options[:verbose]
      logger.quiet! if options[:quiet]
    end

    def load_config(options)
      config_file = options[:config]
      if config_file && File.exists?(config_file) && File.extname(config_file) == '.rb'
        logger.info "Load config from #{config_file}"
        load(config_file)
      end
    end

    def set_params(options)
      if options[:params]
        @params = options[:params]
        logger.info "Parameters: #{@params}"
      end
    end
  end
end
