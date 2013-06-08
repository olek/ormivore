# More info at https://github.com/guard/guard#readme

notification :tmux
notification :terminal_title

guard :rspec,
  :all_on_start => true,
  :run_all => { :cli => '--color' },
  :cli => '--color --format nested' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^app/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^spec/(.+)/shared.*\.rb$}) { |m| "spec/#{m[1]}" }
  watch(%r{^spec/(.+)/.*helpers\.rb$}) { |m| "spec/#{m[1]}" }
  watch(%r{spec/spec_(db_)?helper.rb}) { 'spec' }
  watch('spec/factories.rb') { 'spec' }
  watch(%r{^lib/(.+)\.rb$}) { 'spec' }
end
