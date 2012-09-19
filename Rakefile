require 'spec/rake/spectask'

desc 'run specs'
Spec::Rake::SpecTask.new do |task|
  # task.pattern    = 'spec/{models,javascripts}/**/*_spec.rb'
  task.spec_opts = ['--color', '--format progress', '--timeout 0.1']
  task.spec_files = FileList['spec/**/*_spec.rb']
end
