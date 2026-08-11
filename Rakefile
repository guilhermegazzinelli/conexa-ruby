# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

# Ruby versions the gemspec supports and CI covers. Keep in step with
# .github/workflows/ruby.yml and conexa.gemspec's required_ruby_version.
SUPPORTED_RUBIES = %w[3.1.7 3.2.9 3.3.10 3.4.7].freeze

namespace :spec do
  desc "Run the suite on every supported ruby (#{SUPPORTED_RUBIES.join(", ")}) via mise"
  task :all do
    abort "mise not found — install it, or rely on CI for the matrix" unless system("command -v mise > /dev/null 2>&1")

    installed = `mise ls ruby 2>/dev/null`
    results = SUPPORTED_RUBIES.map do |version|
      unless installed.include?(version)
        puts "\n== ruby #{version}: SKIP (mise install ruby@#{version})"
        next [version, "SKIP"]
      end

      puts "\n#{"=" * 62}\n ruby #{version}\n#{"=" * 62}"

      # A bundle path per version: native extensions are not portable across
      # rubies, so a shared vendor/bundle makes each run clobber the last.
      env = { "BUNDLE_PATH" => "vendor/bundle-#{version}", "BUNDLE_WITHOUT" => "development" }

      ok = system(env, "mise x ruby@#{version} -- bundle install --quiet") &&
           system(env, "mise x ruby@#{version} -- bundle exec rspec --format progress")

      [version, ok ? "PASS" : "FAIL"]
    end

    puts "\n#{"=" * 62}\n summary\n#{"=" * 62}"
    results.each { |version, status| puts format("  %-8s %s", version, status) }

    abort "one or more rubies failed" if results.any? { |(_, status)| status == "FAIL" }
  end
end

desc "Everything CI runs: specs on every supported ruby, then rubocop"
task ci: ["spec:all", :rubocop]

task default: %i[spec rubocop]
