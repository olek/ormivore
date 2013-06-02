# More info at https://github.com/guard/guard#readme

guard :rspec,
  :all_on_start => true,
  :run_all => { :cli => '--color --drb' },
  :cli => '--color --format nested --drb' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^app/(.+)\.rb$})                           { |m| ["spec/#{m[1]}_spec.rb", 'spec/integration'] }
  watch('spec/spec_(db_)?helper.rb')  { 'spec' }
  watch(%r{^lib/(.+)\.rb$})     { 'spec' }
end
