# More info at https://github.com/guard/guard#readme

notification :tmux
notification :terminal_title

skip_extra_adapter_specs = true
#primary_adapter_to_skip = 'memory'
primary_adapter_to_skip = 'sql'

cli = '--color --format nested'
cli += " --tag ~secondary_adapter --tag ~#{primary_adapter_to_skip}_adapter" if skip_extra_adapter_specs

guard :rspec,
  :all_on_start => true,
  :run_all => { :cli => '--color' },
  :cli => cli do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^app/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^spec/(.+)/shared.*\.rb$}) { |m| "spec/#{m[1]}" }
  watch(%r{^spec/(.+)/.*helpers\.rb$}) { |m| "spec/#{m[1]}" }
  watch(%r{spec/spec_(db_)?helper.rb}) { 'spec' }
  watch('spec/factories.rb') { 'spec' }
  watch(%r{^lib/(.+)\.rb$}) { 'spec' }
end
