desc "Run erb_lint on all ERB files"
task :erb_lint do
  puts "Running erb_lint..."
  system("bundle exec erb_lint --lint-all") || exit(1)
end

namespace :erb_lint do
  desc "Run erb_lint with autocorrect on all ERB files"
  task :autocorrect do
    puts "Running erb_lint with autocorrect..."
    system("bundle exec erb_lint --lint-all --autocorrect") || exit(1)
  end
end
