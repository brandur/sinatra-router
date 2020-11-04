# frozen_string_literal: true

require 'bundler'
require 'rake/testtask'

task default: :test

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end
