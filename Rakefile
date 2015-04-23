begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

task :default => :spec

desc "Generate RDoc with YARD"
task :doc => ['doc:generate']

namespace :doc do
  begin
    require 'yard'
    require 'yard/rake/yardoc_task'

    YARD::Rake::YardocTask.new(:generate) do |yt|
      yt.files   =  Dir.glob(File.join('lib', '*.rb')) +
                    Dir.glob(File.join('lib', '**', '*.rb'))

      yt.options = ['--output-dir', 'rdoc', '--readme', 'README.md',
                    '--files', 'LICENSE', '--protected', '--private', '--title',
                    'OA::Graph', '--exclude', 'version.rb']
    end
  rescue LoadError
    desc "Generate RDoc with YARD"
    task :generate do
      abort "Please install the YARD gem to generate rdoc."
    end
  end

  desc "Remove generated documenation"
  task :clean do
    rm_r 'rdoc' if File.exists?('rdoc')
  end
end
