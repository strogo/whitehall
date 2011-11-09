require 'test_helper'

class Admin::NewsArticlesControllerTest < ActionController::TestCase
  setup do
    @user = login_as :policy_writer
  end

  test_controller_is_a Admin::BaseController

  test 'new displays news articles form' do
    get :new

    assert_select "form[action='#{admin_news_articles_path}']" do
      assert_select "input[name='document[title]'][type='text']"
      assert_select "textarea[name='document[body]']"
      assert_select "select[name*='document[documents_related_to_ids]']"
      assert_select "select[name*='document[organisation_ids]']"
      assert_select "select[name*='document[topic_ids]']"
      assert_select "select[name*='document[ministerial_role_ids]']"
      assert_select "select[name*='document[country_ids]']"
      assert_select "input[type='submit']"
    end
  end

  test 'creating should create a new news article' do
    first_topic = create(:topic)
    second_topic = create(:topic)
    first_org = create(:organisation)
    second_org = create(:organisation)
    first_policy = create(:published_policy)
    second_policy = create(:published_policy)
    first_country = create(:country)
    second_country = create(:country)
    attributes = attributes_for(:news_article)

    post :create, document: attributes.merge(
      topic_ids: [first_topic.id, second_topic.id],
      organisation_ids: [first_org.id, second_org.id],
      documents_related_to_ids: [first_policy.id, second_policy.id],
      country_ids: [first_country.id, second_country.id]
    )

    created_news_article = NewsArticle.last
    assert_equal attributes[:title], created_news_article.title
    assert_equal attributes[:body], created_news_article.body
    assert_equal [first_topic, second_topic], created_news_article.topics
    assert_equal [first_org, second_org], created_news_article.organisations
    assert_equal [first_policy, second_policy], created_news_article.documents_related_to
    assert_equal [first_country, second_country], created_news_article.countries
  end

  test 'creating should take the writer to the news article page' do
    post :create, document: attributes_for(:news_article)

    assert_redirected_to admin_news_article_path(NewsArticle.last)
    assert_equal 'The document has been saved', flash[:notice]
  end

  test 'creating with invalid data should leave the writer in the news article editor' do
    attributes = attributes_for(:news_article)
    post :create, document: attributes.merge(title: '')

    assert_equal attributes[:body], assigns(:document).body, "the valid data should not have been lost"
    assert_template "documents/new"
  end

  test 'creating with invalid data should set an alert in the flash' do
    attributes = attributes_for(:news_article)
    post :create, document: attributes.merge(title: '')

    assert_equal 'There are some problems with the document', flash.now[:alert]
  end

  test 'updating should save modified document attributes' do
    first_topic = create(:topic)
    second_topic = create(:topic)
    first_policy = create(:published_policy)
    second_policy = create(:published_policy)
    first_country = create(:country)
    second_country = create(:country)
    news_article = create(:news_article, topics: [first_topic], documents_related_to: [first_policy], countries: [first_country])

    put :update, id: news_article.id, document: {
      title: "new-title",
      body: "new-body",
      topic_ids: [second_topic.id],
      documents_related_to_ids: [second_policy.id],
      country_ids: [second_country.id]
    }

    saved_news_article = news_article.reload
    assert_equal "new-title", saved_news_article.title
    assert_equal "new-body", saved_news_article.body
    assert_equal [second_topic], saved_news_article.topics
    assert_equal [second_policy], saved_news_article.documents_related_to
    assert_equal [second_country], saved_news_article.countries
  end

  test 'updating should remove all topics, related documents and countries if none in params' do
    topic = create(:topic)
    policy = create(:published_policy)
    country = create(:country)

    news_article = create(:news_article, topics: [topic], documents_related_to: [policy], countries: [country])

    put :update, id: news_article, document: {}

    news_article.reload
    assert_equal [], news_article.topics
    assert_equal [], news_article.documents_related_to
    assert_equal [], news_article.countries
  end

  test 'updating should take the writer to the news article page' do
    news_article = create(:news_article)
    put :update, id: news_article.id, document: {title: 'new-title', body: 'new-body'}

    assert_redirected_to admin_news_article_path(news_article)
    assert_equal 'The document has been saved', flash[:notice]
  end

  test 'updating with invalid data should not save the news article' do
    attributes = attributes_for(:news_article)
    news_article = create(:news_article, attributes)
    put :update, id: news_article.id, document: attributes.merge(title: '')

    assert_equal attributes[:title], news_article.reload.title
    assert_template "documents/edit"
    assert_equal 'There are some problems with the document', flash.now[:alert]
  end

  test 'updating a stale news article should render edit page with conflicting news article' do
    news_article = create(:draft_news_article)
    lock_version = news_article.lock_version
    news_article.touch

    put :update, id: news_article, document: news_article.attributes.merge(lock_version: lock_version)

    assert_template 'edit'
    conflicting_news_article = news_article.reload
    assert_equal conflicting_news_article, assigns[:conflicting_document]
    assert_equal conflicting_news_article.lock_version, assigns[:document].lock_version
    assert_equal %{This document has been saved since you opened it}, flash[:alert]

    assert_select ".document.conflict" do
      assert_select "h1", "Organisations"
      assert_select "h1", "Topics"
      assert_select "h1", "Ministers"
      assert_select "h1", "Countries"
    end
  end

  test "cancelling a new news article takes the user to the list of drafts" do
    get :new
    assert_select "a[href=#{admin_documents_path}]", text: /cancel/i, count: 1
  end

  test "cancelling an existing news article takes the user to that news article" do
    draft_news_article = create(:draft_news_article)
    get :edit, id: draft_news_article
    assert_select "a[href=#{admin_news_article_path(draft_news_article)}]", text: /cancel/i, count: 1
  end

  test 'updating a submitted news article with bad data should show errors' do
    attributes = attributes_for(:submitted_news_article)
    submitted_news_article = create(:submitted_news_article, attributes)
    put :update, id: submitted_news_article, document: attributes.merge(title: '')

    assert_template 'edit'
  end

  test "should render the content using govspeak markup" do
    draft_news_article = create(:draft_news_article, body: "body-in-govspeak")
    Govspeak::Document.stubs(:to_html).with("body-in-govspeak").returns("body-in-html")

    get :show, id: draft_news_article

    assert_select ".body", text: "body-in-html"
  end

  test "should display the countries to which the news article relates" do
    first_country = create(:country)
    second_country = create(:country)
    draft_news_article = create(:draft_news_article, countries: [first_country, second_country])

    get :show, id: draft_news_article

    assert_select_object(first_country)
    assert_select_object(second_country)
  end

  test "should indicate that the news article does not relate to any country" do
    draft_news_article = create(:draft_news_article, countries: [])

    get :show, id: draft_news_article

    assert_select "p", "This document isn't assigned to any countries."
  end

  should_be_rejectable :news_article
  should_be_force_publishable :news_article
  should_be_able_to_delete_a_document :news_article

  should_link_to_public_version_when_published :news_article
  should_not_link_to_public_version_when_not_published :news_article
end
