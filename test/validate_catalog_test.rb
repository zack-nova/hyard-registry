require "fileutils"
require "open3"
require "tmpdir"
require "minitest/autorun"

class ValidateCatalogTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  VALIDATOR = File.join(REPO_ROOT, "scripts", "validate_catalog.rb")

  def test_valid_catalog_passes
    stdout, stderr, status = run_validator(REPO_ROOT)

    assert status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
    assert_includes stdout, "Catalog validation passed"
  end

  def test_invalid_yaml_fails
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "curated"))
      File.write(File.join(dir, "curated", "index.yaml"), "schema_version: [\n")

      stdout, stderr, status = run_validator(dir)

      refute status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
      assert_includes stderr, "curated/index.yaml"
      assert_includes stderr, "invalid YAML"
    end
  end

  def test_missing_schema_version_fails
    Dir.mktmpdir do |dir|
      write_valid_catalog(dir)
      File.write(File.join(dir, "curated", "index.yaml"), "curated: {}\n")

      stdout, stderr, status = run_validator(dir)

      refute status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
      assert_includes stderr, "curated/index.yaml"
      assert_includes stderr, "schema_version must be 1"
    end
  end

  def test_namespace_paths_must_match_declared_namespace
    Dir.mktmpdir do |dir|
      write_valid_catalog(dir)
      File.write(File.join(dir, "namespaces", "acme.yaml"), <<~YAML)
        schema_version: 1
        namespace: other
      YAML
      File.write(File.join(dir, "packages", "acme", "index.yaml"), <<~YAML)
        schema_version: 1
        namespace: other
        packages: {}
      YAML

      stdout, stderr, status = run_validator(dir)

      refute status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
      assert_includes stderr, "namespaces/acme.yaml: namespace must match path namespace acme"
      assert_includes stderr, "packages/acme/index.yaml: namespace must match path namespace acme"
    end
  end

  def test_package_status_must_be_known
    Dir.mktmpdir do |dir|
      write_valid_catalog(dir)
      package_index = File.read(File.join(dir, "packages", "acme", "index.yaml"))
      File.write(File.join(dir, "packages", "acme", "index.yaml"), package_index.sub("status: active", "status: quarantined"))
      curated_index = File.read(File.join(dir, "curated", "index.yaml"))
      File.write(File.join(dir, "curated", "index.yaml"), curated_index.sub("status: active", "status: quarantined"))

      stdout, stderr, status = run_validator(dir)

      refute status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
      assert_includes stderr, "packages/acme/index.yaml: package acme/docs status must be one of active, deprecated, yanked, blocked"
      assert_includes stderr, "curated/index.yaml: curated handle docs status must be one of active, deprecated, yanked, blocked"
    end
  end

  def test_latest_dist_tag_must_point_to_existing_version
    Dir.mktmpdir do |dir|
      write_valid_catalog(dir)
      package_index = File.read(File.join(dir, "packages", "acme", "index.yaml"))
      File.write(File.join(dir, "packages", "acme", "index.yaml"), package_index.sub('latest: "0.1.0"', 'latest: "0.2.0"'))

      stdout, stderr, status = run_validator(dir)

      refute status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
      assert_includes stderr, "packages/acme/index.yaml: package acme/docs latest dist-tag points to missing version 0.2.0"
    end
  end

  def test_curated_handle_target_must_exist
    Dir.mktmpdir do |dir|
      write_valid_catalog(dir)
      curated_index = File.read(File.join(dir, "curated", "index.yaml"))
      File.write(File.join(dir, "curated", "index.yaml"), curated_index.sub("target: acme/docs", "target: acme/missing"))

      stdout, stderr, status = run_validator(dir)

      refute status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
      assert_includes stderr, "curated/index.yaml: curated handle docs target acme/missing does not exist"
    end
  end

  private

  def run_validator(path)
    Open3.capture3("ruby", VALIDATOR, path)
  end

  def write_valid_catalog(dir)
    FileUtils.mkdir_p(File.join(dir, "curated"))
    FileUtils.mkdir_p(File.join(dir, "namespaces"))
    FileUtils.mkdir_p(File.join(dir, "packages", "acme"))
    File.write(File.join(dir, "namespaces", "acme.yaml"), <<~YAML)
      schema_version: 1
      namespace: acme
      owners:
        - platform: github
          owner: acme
      status: active
    YAML
    File.write(File.join(dir, "packages", "acme", "index.yaml"), <<~YAML)
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
                repository: https://example.com/acme/docs.git
                ref: orbit-template/docs
                commit: 1111111111111111111111111111111111111111
    YAML
    File.write(File.join(dir, "curated", "index.yaml"), <<~YAML)
      schema_version: 1
      curated:
        docs:
          target: acme/docs
          status: active
    YAML
  end
end
