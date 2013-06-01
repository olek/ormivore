require 'rspec/core/rake_task'

desc 'Run specs'
RSpec::Core::RakeTask.new(:spec) do |task|
  # task.pattern    = 'spec/{models,javascripts}/**/*_spec.rb'
  # task.rspec_opts = ['--color', '--format progress', '--timeout 0.1']
  task.rspec_opts = ['--color', '--format progress']
  # task.spec_files = FileList['spec/**/*_spec.rb']
end

task :default => :spec
