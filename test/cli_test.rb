require_relative './test_helper'
require 'tumugi/cli'

class Tumugi::CLITest < Tumugi::Test::TumugiTestCase
  examples = {
    'concurrent_task_run' => ['concurrent_task_run.rb', 'task1'],
    'data_pipeline' => ['data_pipeline.rb', 'sum'],
    'simple' => ['simple.rb', 'task1'],
    'target' => ['target.rb', 'task1'],
    'task_inheritance' => ['task_inheritance.rb', 'task1'],
    'task_parameter' => ['task_parameter.rb', 'task1'],
  }

  failed_examples = {
    'fail_first_task' => ['fail_first_task.rb', 'task1'],
    'fail_intermediate_task' => ['fail_intermediate_task.rb', 'task1'],
    'fail_last_task' => ['fail_last_task.rb', 'task1'],
    'event_callbacks' => ['event_callbacks.rb', 'task1'],
  }

  config_section_examples = {
    'config_section' => ['config_section.rb', 'task1'],
  }

  setup do
    system('rm -rf tmp/tumugi_*')
  end

  sub_test_case 'run' do
    data do
      data_set = {}
      examples.each do |k, v|
        [1, 2, 8].each do |n|
          data_set["#{k}_workers_#{n}"] = (v.dup << n)
        end
      end
      data_set
    end
    test 'success' do |(file, task, worker)|
      assert_run_success("examples/#{file}", task, workers: worker, params: { 'key1' => 'value1' }, config: "examples/tumugi_config.rb", verbose: ENV['DEBUG'], quiet: !ENV['DEBUG'])
    end

    data do
      data_set = {}
      failed_examples.each do |k, v|
        [1, 2, 8].each do |n|
          data_set["#{k}_workers_#{n}"] = (v.dup << n)
        end
      end
      data_set
    end
    test 'fail' do |(file, task, worker)|
      assert_run_fail("examples/#{file}", task, workers: worker, config: "examples/tumugi_config.rb", verbose: ENV['DEBUG'], quiet: !ENV['DEBUG'])
    end

    data(config_section_examples)
    test 'config_section' do |(file, task)|
      assert_run_success("examples/#{file}", task, config: "examples/tumugi_config_with_section.rb", output: 'tmp/tumugi.log', verbose: ENV['DEBUG'], quiet: !ENV['DEBUG'])
    end

    test 'logfile' do
      assert_run_success("examples/simple.rb", "task1", out: "tmp/tumugi.log", config: "examples/tumugi_config.rb", verbose: ENV['DEBUG'], quiet: !ENV['DEBUG'])
      assert_true(File.exist?('tmp/tumugi.log'))
    end

    test 'workflow has syntax error' do
      assert_run_fail("test/data/invalid_workflow.rb", "task1", verbose: ENV['DEBUG'], quiet: !ENV['DEBUG'])
    end

    test 'config has syntax error' do
      assert_run_fail("examples/simple.rb", "task1", config: "test/data/invalid_config.rb", verbose: ENV['DEBUG'], quiet: !ENV['DEBUG'])
    end

    test 'run as as a default command' do
      assert_true(system("exe/tumugi -f examples/simple.rb task1"))
    end
  end

  sub_test_case 'show' do
    data(examples)
    test 'without out' do |(file, task)|
      text = capture_stdout do
        assert_show_success("examples/#{file}", task, params: { 'key1' => 'value1' }, verbose: ENV['DEBUG'], quiet: !ENV['DEBUG'])
      end
      assert_true(text.include?('digraph G'))
      assert_false(text.include?('INFO'))
    end

    data do
      data_set = {}
      examples.each do |k, v|
        %w(dot jpg pdf png svg).each do |fmt|
          data_set["#{k}_#{fmt}"] = (v.dup << fmt)
        end
      end
      data_set
    end
    test 'with valid output' do |(file, task, format)|
      output_file = "tmp/#{file}.#{format}"
      assert_show_success("examples/#{file}", task, out: output_file, params: { 'key1' => 'value1' }, verbose: ENV['DEBUG'], quiet: !ENV['DEBUG'])
      assert_true(File.exist?(output_file))
    end
  end

  sub_test_case 'new' do
    test 'plugin' do
      output_path = './tmp/test_cli_new_plugin'
      Tumugi::CLI.new.invoke(:new, ['plugin', 'test'], path: output_path)

      generator = Tumugi::Command::New::PluginGenerator.new('test', path: output_path)
      generator.templates.each do |template|
        assert_true(File.exist?("#{output_path}/tumugi-plugin-test/#{template[1]}"))
      end
    end

    test 'project' do
      output_path = './tmp/test_cli_new_project'
      Tumugi::CLI.new.invoke(:new, ['project', 'test'], path: output_path)

      generator = Tumugi::Command::New::ProjectGenerator.new('test', path: output_path)
      generator.templates.each do |template|
        assert_true(File.exist?("#{output_path}/test/#{template[1]}"))
      end
    end

    test 'unsupported' do
      assert_raise(Thor::Error) do
        Tumugi::CLI.new.invoke(:new, ['unsupported', 'test'])
      end
    end
  end

  test 'init' do
    output_path = './tmp/test_cli_init'
    Tumugi::CLI.new.invoke(:init, [output_path])
  end
end
