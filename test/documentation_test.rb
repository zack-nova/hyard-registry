require "minitest/autorun"

class DocumentationTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  POLICY_DOC = File.join(REPO_ROOT, "docs", "submission-review-policy.md")
  README = File.join(REPO_ROOT, "README.md")

  def test_submission_review_policy_is_documented
    assert File.file?(POLICY_DOC), "expected docs/submission-review-policy.md to exist"

    text = File.read(POLICY_DOC)

    assert_includes text, "publish the package"
    assert_includes text, "hyard registry entry"
    assert_includes text, "Git-platform user or organization"
    assert_includes text, "Curated Handle"
    assert_includes text, "preview-only"
    assert_includes text, "active"
    assert_includes text, "deprecated"
    assert_includes text, "yanked"
    assert_includes text, "blocked"
    assert_includes text, "revalidates"
    assert_includes text, "does not trust local validation evidence"
  end

  def test_readme_links_submission_review_policy
    assert_includes File.read(README), "docs/submission-review-policy.md"
  end
end
