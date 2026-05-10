#!/usr/bin/env ruby

require "pathname"
require "set"
require "yaml"

repo_root = ARGV.fetch(0, ".")

unless Dir.exist?(repo_root)
  warn "Catalog root does not exist: #{repo_root}"
  exit 1
end

root = Pathname.new(repo_root).expand_path
errors = []
valid_statuses = %w[active deprecated yanked blocked]
package_handles = Set.new
curated_targets = []

Dir.glob(root.join("**", "*.yaml")).sort.each do |path|
  relative = Pathname.new(path).relative_path_from(root).to_s
  begin
    document = YAML.load_file(path)
  rescue Psych::SyntaxError => e
    errors << "#{relative}: invalid YAML: #{e.message}"
    next
  end
  unless document.is_a?(Hash)
    errors << "#{relative}: YAML document must be a mapping"
    next
  end
  unless document["schema_version"] == 1
    errors << "#{relative}: schema_version must be 1"
  end
  case relative
  when %r{\Anamespaces/([^/]+)\.yaml\z}
    path_namespace = Regexp.last_match(1)
    unless document["namespace"] == path_namespace
      errors << "#{relative}: namespace must match path namespace #{path_namespace}"
    end
  when %r{\Apackages/([^/]+)/index\.yaml\z}
    path_namespace = Regexp.last_match(1)
    unless document["namespace"] == path_namespace
      errors << "#{relative}: namespace must match path namespace #{path_namespace}"
    end
    packages = document["packages"]
    if packages.is_a?(Hash)
      packages.each do |name, package|
        package_handles << "#{path_namespace}/#{name}"
        next unless package.is_a?(Hash)

        status = package["status"]
        unless valid_statuses.include?(status)
          errors << "#{relative}: package #{path_namespace}/#{name} status must be one of #{valid_statuses.join(", ")}"
        end
        latest = package.dig("dist_tags", "latest")
        versions = package["versions"]
        if latest && versions.is_a?(Hash) && !versions.key?(latest.to_s)
          errors << "#{relative}: package #{path_namespace}/#{name} latest dist-tag points to missing version #{latest}"
        end
      end
    end
  when "curated/index.yaml"
    curated = document["curated"]
    if curated.is_a?(Hash)
      curated.each do |name, entry|
        next unless entry.is_a?(Hash)

        curated_targets << [relative, name, entry["target"]]
        status = entry["status"]
        unless valid_statuses.include?(status)
          errors << "#{relative}: curated handle #{name} status must be one of #{valid_statuses.join(", ")}"
        end
      end
    end
  end
end

curated_targets.each do |relative, name, target|
  unless package_handles.include?(target)
    errors << "#{relative}: curated handle #{name} target #{target} does not exist"
  end
end

unless errors.empty?
  errors.each { |error| warn error }
  exit 1
end

puts "Catalog validation passed"
