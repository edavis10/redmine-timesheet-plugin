#!/usr/bin/env ruby
require "fileutils"

require 'rake/clean'
CLEAN.include('**/semantic.cache','**/*~')

desc "Generate a changelog from svn"
task :changelog do
  svn2cl_options = "--group-by-day --break-before-msg --linelen=120 -o CHANGELOG.txt"
  system("svn2cl #{svn2cl_options}")
end
