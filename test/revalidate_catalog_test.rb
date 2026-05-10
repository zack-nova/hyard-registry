require "fileutils"
require "open3"
require "tmpdir"
require "minitest/autorun"

class RevalidateCatalogTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  REVALIDATOR = File.join(REPO_ROOT, "scripts", "revalidate_catalog.rb")

  def test_valid_orbit_package_revalidates_source_and_installability
    Dir.mktmpdir do |dir|
      source = create_orbit_source_repo(File.join(dir, "source"))
      commit = git(source, "rev-parse", "HEAD").strip
      catalog = File.join(dir, "catalog")
      write_catalog(catalog, source, commit)
      hyard_log = File.join(dir, "hyard.log")
      hyard = write_fake_hyard(File.join(dir, "hyard"), hyard_log)

      stdout, stderr, status = run_revalidator(catalog, hyard)

      assert status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
      assert_includes stdout, "Registry revalidation passed"
      assert_includes File.read(hyard_log), "install #{source} --ref orbit-template/docs --dry-run"
    end
  end

  def test_missing_ref_reports_actionable_failure
    Dir.mktmpdir do |dir|
      source = create_orbit_source_repo(File.join(dir, "source"))
      commit = git(source, "rev-parse", "HEAD").strip
      catalog = File.join(dir, "catalog")
      write_catalog(catalog, source, commit, ref: "missing/ref")
      hyard = write_fake_hyard(File.join(dir, "hyard"), File.join(dir, "hyard.log"))

      stdout, stderr, status = run_revalidator(catalog, hyard)

      refute status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
      assert_includes stderr, "acme/docs@0.1.0"
      assert_includes stderr, "ref missing/ref did not resolve"
    end
  end

  def test_package_identity_mismatch_reports_expected_and_actual_identity
    Dir.mktmpdir do |dir|
      source = create_orbit_source_repo(File.join(dir, "source"))
      commit = git(source, "rev-parse", "HEAD").strip
      catalog = File.join(dir, "catalog")
      write_catalog(catalog, source, commit, expected_name: "wrong")
      hyard = write_fake_hyard(File.join(dir, "hyard"), File.join(dir, "hyard.log"))

      stdout, stderr, status = run_revalidator(catalog, hyard)

      refute status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
      assert_includes stderr, "package identity mismatch"
      assert_includes stderr, '"name"=>"wrong"'
      assert_includes stderr, '"name"=>"docs"'
    end
  end

  def test_installability_failure_reports_package_context
    Dir.mktmpdir do |dir|
      source = create_orbit_source_repo(File.join(dir, "source"))
      commit = git(source, "rev-parse", "HEAD").strip
      catalog = File.join(dir, "catalog")
      write_catalog(catalog, source, commit)
      hyard = write_fake_hyard(File.join(dir, "hyard"), File.join(dir, "hyard.log"), fail_install: true)

      stdout, stderr, status = run_revalidator(catalog, hyard)

      refute status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
      assert_includes stderr, "acme/docs@0.1.0"
      assert_includes stderr, "install preview failed"
    end
  end

  private

  def run_revalidator(path, hyard)
    Open3.capture3("ruby", REVALIDATOR, path, "--hyard-bin", hyard)
  end

  def create_orbit_source_repo(path)
    FileUtils.mkdir_p(File.join(path, ".harness", "orbits"))
    git(path, "init", "-q")
    git(path, "config", "user.email", "test@example.com")
    git(path, "config", "user.name", "Test User")
    File.write(File.join(path, ".harness", "orbits", "docs.yaml"), <<~YAML)
      package:
        type: orbit
        name: docs
    YAML
    git(path, "add", ".")
    git(path, "commit", "-qm", "Add docs orbit")
    git(path, "checkout", "-qb", "orbit-template/docs")
    path
  end

  def write_catalog(path, source, commit, ref: "orbit-template/docs", expected_name: "docs")
    FileUtils.mkdir_p(File.join(path, "curated"))
    FileUtils.mkdir_p(File.join(path, "namespaces"))
    FileUtils.mkdir_p(File.join(path, "packages", "acme"))
    File.write(File.join(path, "namespaces", "acme.yaml"), <<~YAML)
      schema_version: 1
      namespace: acme
      owners:
        - platform: github
          owner: acme
      status: active
    YAML
    File.write(File.join(path, "curated", "index.yaml"), <<~YAML)
      schema_version: 1
      curated: {}
    YAML
    File.write(File.join(path, "packages", "acme", "index.yaml"), <<~YAML)
      schema_version: 1
      namespace: acme
      packages:
        docs:
          handle: acme/docs
          status: active
          package:
            type: orbit
            name: docs
          dist_tags:
            latest: "0.1.0"
          versions:
            "0.1.0":
              locator:
                kind: git
                repository: #{source}
                ref: #{ref}
                commit: #{commit}
              validation:
                package_manifest: .harness/orbits/docs.yaml
                package_identity:
                  type: orbit
                  name: #{expected_name}
    YAML
  end

  def write_fake_hyard(path, log, fail_install: false)
    File.write(path, <<~RUBY)
      #!/usr/bin/env ruby
      File.open(#{log.inspect}, "a") { |file| file.puts(ARGV.join(" ")) }
      if #{fail_install.inspect} && ARGV[0] == "install"
        warn "fake install failure"
        exit 1
      end
      if ARGV[0, 2] == ["create", "runtime"]
        Dir.mkdir(ARGV[2]) unless Dir.exist?(ARGV[2])
      end
      exit 0
    RUBY
    File.chmod(0o755, path)
    path
  end

  def git(path, *args)
    FileUtils.mkdir_p(path)
    stdout, stderr, status = Open3.capture3("git", "-C", path, *args)
    raise "git #{args.join(" ")} failed: #{stderr}" unless status.success?

    stdout
  end
end
