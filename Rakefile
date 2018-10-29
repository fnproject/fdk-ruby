task default: %w[test]

task :test do
	  ruby "tests/test_fdk.rb"
end

require 'rubocop/rake_task'
desc "run RuboCop on lib directory"
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ["lib/**/*.rb"]
end
