namespace :test do
  # copy/redefine out of Rails
  task :run do
    errors = %w(test:units test:functionals test:integration test:lib).collect do |task|
      begin
        Rake::Task[task].invoke
        nil
      rescue => e
        { task: task, exception: e }
      end
    end.compact

    if errors.any?
      puts errors.map { |e| "Errors running #{e[:task]}! #{e[:exception].inspect}" }.join("\n")
      abort
    end
  end

  Rake::TestTask.new(lib: "test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'test/{lib}/**/*_test.rb'
  end
end