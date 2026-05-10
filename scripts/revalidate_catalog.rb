#!/usr/bin/env ruby

require "fileutils"
require "date"
require "open3"
require "optparse"
require "pathname"
require "tmpdir"
require "yaml"

options = {
  hyard_bin: ENV.fetch("HYARD_BIN", "hyard")
}

parser = OptionParser.new do |opts|
  opts.on("--hyard-bin PATH", "Path to the hyard executable") do |path|
    options[:hyard_bin] = path
  end
end

repo_root = parser.parse!(ARGV).fetch(0, ".")
root = Pathname.new(repo_root).expand_path
errors = []

def capture_command(*args)
  stdout, stderr, status = Open3.capture3(*args)
  [stdout, stderr, status]
end

def command!(errors, context, *args)
  stdout, stderr, status = capture_command(*args)
  unless status.success?
    errors << "#{context}: #{stderr.strip}"
  end
  [stdout, status.success?]
end

def git!(errors, context, *args)
  command!(errors, context, "git", *args)
end

validator = File.join(__dir__, "validate_catalog.rb")
_, structural_stderr, structural_status = capture_command("ruby", validator, root.to_s)
unless structural_status.success?
  warn structural_stderr
  exit 1
end

Dir.glob(root.join("packages", "*", "index.yaml")).sort.each do |index_path|
  relative = Pathname.new(index_path).relative_path_from(root).to_s
  index = YAML.load_file(index_path)
  namespace = index["namespace"]
  packages = index["packages"]
  next unless packages.is_a?(Hash)

  packages.each do |package_name, package|
    next unless package.is_a?(Hash)

    versions = package["versions"]
    next unless versions.is_a?(Hash)

    versions.each do |version, entry|
      context = "#{relative}: #{namespace}/#{package_name}@#{version}"
      unless entry.is_a?(Hash)
        errors << "#{context}: version entry must be a mapping"
        next
      end

      locator = entry["locator"]
      validation = entry["validation"] || {}
      repository = locator && locator["repository"]
      ref = locator && locator["ref"]
      commit = locator && locator["commit"]

      if [repository, ref, commit].any? { |value| value.to_s.empty? }
        errors << "#{context}: locator repository, ref, and commit are required"
        next
      end

      ref_stdout, ref_ok = git!(errors, context, "ls-remote", repository, ref)
      if ref_ok && ref_stdout.strip.empty?
        errors << "#{context}: ref #{ref} did not resolve"
        next
      end

      Dir.mktmpdir do |dir|
        git!(errors, context, "-C", dir, "init", "-q")
        _, fetched = git!(errors, context, "-C", dir, "fetch", "--depth=1", repository, commit)
        next unless fetched

        _, commit_ok = git!(errors, context, "-C", dir, "cat-file", "-e", "#{commit}^{commit}")
        next unless commit_ok

        manifest_path = validation["package_manifest"]
        if manifest_path.to_s.empty?
          errors << "#{context}: validation.package_manifest is required"
          next
        end

        manifest_stdout, manifest_ok = git!(errors, context, "-C", dir, "show", "#{commit}:#{manifest_path}")
        next unless manifest_ok

        begin
          manifest = YAML.safe_load(manifest_stdout, permitted_classes: [Date, Time])
        rescue Psych::SyntaxError => e
          errors << "#{context}: package manifest is invalid YAML: #{e.message}"
          next
        end
        unless manifest.is_a?(Hash)
          errors << "#{context}: package manifest must be a mapping"
          next
        end

        expected_identity = validation["package_identity"] || {}
        actual_type = manifest.dig("package", "type")
        actual_name = manifest.dig("package", "name")
        if package.dig("package", "type") == "harness"
          actual_type ||= "harness"
          actual_name ||= manifest.dig("template", "harness_id")
        end
        if actual_type != expected_identity["type"] || actual_name != expected_identity["name"]
          errors << "#{context}: package identity mismatch, expected #{expected_identity.inspect}, got #{ { "type" => actual_type, "name" => actual_name }.inspect }"
          next
        end

        package_type = package.dig("package", "type")
        case package_type
        when "orbit"
          runtime_dir = File.join(dir, "runtime")
          _, create_ok = command!(errors, context, options[:hyard_bin], "create", "runtime", runtime_dir)
          next unless create_ok

          _, install_ok = command!(errors, context, options[:hyard_bin], "install", repository, "--ref", ref, "--dry-run", "--path", runtime_dir, "--progress", "quiet")
          errors << "#{context}: install preview failed" unless install_ok
        when "harness"
          _, clone_ok = command!(errors, context, options[:hyard_bin], "clone", repository, package_name, "--path", dir, "--ref", ref)
          errors << "#{context}: harness clone validation failed" unless clone_ok
        else
          errors << "#{context}: unsupported package type #{package_type.inspect}"
        end
      end
    end
  end
end

unless errors.empty?
  errors.each { |error| warn error }
  exit 1
end

puts "Registry revalidation passed"
