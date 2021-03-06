require "test_helper"

class Edition::WorkflowTest < ActiveSupport::TestCase
  test "should build a draft copy of the existing edition with the supplied creator" do
    published_edition = create(:published_edition)
    new_creator = create(:policy_writer)
    draft_edition = published_edition.create_draft(new_creator)

    refute draft_edition.published?
    refute draft_edition.submitted?
    assert_equal new_creator, draft_edition.creator
    assert_equal published_edition.title, draft_edition.title
    assert_equal published_edition.body, draft_edition.body
  end

  test "should raise an exception when attempting to build a draft copy of an draft edition" do
    draft_edition = create(:draft_edition)
    new_creator = create(:policy_writer)
    e = assert_raises(RuntimeError) { draft_edition.create_draft(new_creator) }
    assert_equal "Cannot create new edition based on edition in the draft state", e.message
  end

  test "should raise an exception when attempting to build a draft copy of an archived edition" do
    archived_edition = create(:archived_edition)
    new_creator = create(:policy_writer)
    e = assert_raises(RuntimeError) { archived_edition.create_draft(new_creator) }
    assert_equal "Cannot create new edition based on edition in the archived state", e.message
  end

  test "should not copy create and update time when creating draft" do
    published_edition = create(:published_edition)
    Timecop.travel 1.minute.from_now
    draft_edition = published_edition.create_draft(create(:policy_writer))

    refute_equal published_edition.created_at, draft_edition.created_at
    refute_equal published_edition.updated_at, draft_edition.updated_at
  end

  test "should not copy change note when creating draft" do
    published_edition = create(:published_edition, change_note: "change-note")
    draft_edition = published_edition.create_draft(create(:policy_writer))

    refute_equal published_edition.change_note, draft_edition.change_note
  end

  test "should not copy minor change flag when creating draft" do
    published_edition = create(:published_edition, minor_change: true)
    draft_edition = published_edition.create_draft(create(:policy_writer))

    assert_equal false, draft_edition.minor_change
  end

  test "should not copy force published flag when creating draft" do
    published_edition = create(:published_edition, force_published: true)
    draft_edition = published_edition.create_draft(create(:policy_writer))

    refute draft_edition.force_published
  end

  test "should copy time of first publication when creating draft" do
    published_edition = create(:published_edition, first_published_at: 1.week.ago)
    Timecop.travel 1.hour.from_now
    draft_edition = published_edition.create_draft(create(:policy_writer))

    assert_equal published_edition.first_published_at, draft_edition.first_published_at
  end

  test "should build a draft copy with references to topics, organisations, ministerial roles & countries" do
    topic = create(:topic)
    organisation = create(:organisation)
    ministerial_role = create(:ministerial_role)
    country = create(:country)

    published_policy = create(:published_policy, topics: [topic], organisations: [organisation], ministerial_roles: [ministerial_role], countries: [country])

    draft_policy = published_policy.create_draft(create(:policy_writer))

    assert_equal [topic], draft_policy.topics
    assert_equal [organisation], draft_policy.organisations
    assert_equal [ministerial_role], draft_policy.ministerial_roles
    assert_equal [country], draft_policy.countries
  end

  test "should build a draft copy with copies of supporting pages" do
    published_policy = create(:published_policy)
    supporting_page = create(:supporting_page, edition: published_policy)
    draft_policy = published_policy.create_draft(create(:policy_writer))

    assert draft_policy.valid?

    assert new_supporting_page = draft_policy.supporting_pages.last
    refute_equal supporting_page, new_supporting_page
    assert_equal supporting_page.title, new_supporting_page.title
    assert_equal supporting_page.body, new_supporting_page.body
  end

  test "should build a draft copy with references to related policies" do
    policy_1 = create(:published_policy)
    policy_2 = create(:published_policy)
    publication = create(:published_publication, related_policies: [policy_1, policy_2])

    draft = publication.create_draft(create(:policy_writer))
    assert draft.valid?

    assert draft.related_policies.include?(policy_1)
    assert draft.related_policies.include?(policy_2)
  end

  test "should build a draft copy preserving ordering with topic" do
    topic = create(:topic)
    published_policy = create(:published_policy, topics: [topic])
    association = topic.topic_memberships.where(edition_id: published_policy.id).first
    association.update_attributes(ordering: 31)

    draft_policy = published_policy.create_draft(create(:policy_writer))

    new_association = topic.topic_memberships.where(edition_id: draft_policy.id).first
    assert_equal 31, new_association.ordering
  end

  test "should build a draft copy even if parent is invalid" do
    published_policy = create(:published_policy)
    published_policy.update_attribute(:title, nil)
    refute published_policy.valid?
    draft_policy = published_policy.create_draft(create(:policy_writer))
    assert draft_policy.persisted?
  end
end