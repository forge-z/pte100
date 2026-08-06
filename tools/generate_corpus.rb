#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "yaml"

root = File.expand_path("..", __dir__)
source = File.join(root, "corpus", "cases.yaml")
data = YAML.safe_load(File.read(source, encoding: "UTF-8"), permitted_classes: [], aliases: false)

%w[positive negative].each do |kind|
  directory = File.join(root, "corpus", "fixtures", kind)
  FileUtils.mkdir_p(directory)
  data.fetch("cases").select { |item| item.fetch("class") == kind }.each do |item|
    path = File.join(directory, "#{item.fetch("id")}.md")
    text = item.fetch("text")
    text += "\n" unless text.end_with?("\n")
    File.write(path, text, encoding: "UTF-8")
  end
end

puts "Geradas #{data.fetch("cases").length} fixtures em corpus/fixtures/."
