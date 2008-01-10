#!/usr/bin/env ruby
require "fileutils"

require 'rake/clean'
CLEAN.include('**/semantic.cache','**/*~')
PROJECT = 'redmine_timesheet_plugin'
ZIP_FILE = "#{PROJECT}.zip"

desc "Generate a changelog from svn"
task :changelog do
  svn2cl_options = "--group-by-day --break-before-msg --linelen=120 -o CHANGELOG.txt"
  system("svn2cl #{svn2cl_options}")
end

desc "Zip of the folder for release"
task :zip => [:clean] do
  require 'zip/zip'
  require 'zip/zipfilesystem'

  # check to see if the file exists already, and if it does, delete it.
  if File.file?(ZIP_FILE)
    File.delete(ZIP_FILE)
  end

  # open or create the zip file
  Zip::ZipFile.open(ZIP_FILE, Zip::ZipFile::CREATE) do |zipfile|
    zipfile.mkdir(PROJECT)

    # Should skip svn files
    files = Dir['**/*.*']

    files.each do |file|
      print "Adding #{file} ...."
      zipfile.add(PROJECT + '/' + file, file)
      puts ". done"
    end
  end

  # set read permissions on the file
  File.chmod(0644, ZIP_FILE)
end
