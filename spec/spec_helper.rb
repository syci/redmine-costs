# prevent case where we are using rubygems and test-unit 2.x is installed
begin
  gem "test-unit", "~> 1.2.3"
rescue LoadError
end

begin
  require "config/environment" unless defined? RAILS_ROOT
  require RAILS_ROOT + '/spec/spec_helper'
rescue LoadError => error
  puts <<-EOS

    You need to install rspec in your Redmine project.
    Please execute the following code:
    
      gem install rspec-rails
      script/generate rspec

  EOS
  raise error
end

require File.join(File.dirname(__FILE__), "..", "init.rb")