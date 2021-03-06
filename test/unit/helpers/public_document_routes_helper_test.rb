require 'test_helper'

class PublicDocumentRoutesHelperTest < ActionView::TestCase
  setup do
    @request  = ActionController::TestRequest.new
    ActionController::Base.default_url_options = {}
  end
  attr_reader :request

  test 'uses the document to generate the route' do
    policy = create(:policy)
    assert_equal policy_path(policy.document), public_document_path(policy)
  end

  test 'respects additional path options' do
    policy = create(:policy)
    assert_equal policy_path(policy.document, anchor: 'additional'), public_document_path(policy, anchor: 'additional')
  end

  test 'returns the policy_path for Policy instances' do
    policy = create(:policy)
    assert_equal policy_path(policy.document), public_document_path(policy)
  end

  test 'returns the publication_path for Publication instances' do
    publication = create(:publication)
    assert_equal publication_path(publication.document), public_document_path(publication)
  end

  test 'returns the announcement_path for NewsArticle instances' do
    news_article = create(:news_article)
    assert_equal announcement_path(news_article.document), public_document_path(news_article)
  end

  test 'returns the announcement_path for Speech instances' do
    speech = create(:speech)
    assert_equal announcement_path(speech.document), public_document_path(speech)
  end

  test 'returns the consultation_path for Consultation instances' do
    consultation = create(:consultation)
    assert_equal consultation_path(consultation.document), public_document_path(consultation)
  end

  test 'returns the singleton consultation_response_path for ConsultationResponse instances' do
    consultation_response = create(:consultation_response)
    assert_equal consultation_response_path(consultation_response.consultation.document), public_document_path(consultation_response)
  end

  test 'uses the document to generate the supporting page route' do
    policy = create(:policy)
    supporting_page = create(:supporting_page, edition: policy)
    assert_equal policy_supporting_page_path(policy.document, supporting_page), public_supporting_page_path(policy, supporting_page)
  end

  test 'returns public document URL including host in production environment' do
    request.host = "whitehall.production.alphagov.co.uk"
    edition = create(:published_policy)
    assert_equal "www.gov.uk", URI.parse(public_document_url(edition)).host
  end

  test 'returns public document URL including host in public production environment' do
    request.host = "www.gov.uk"
    edition = create(:published_policy)
    assert_equal "www.gov.uk", URI.parse(public_document_url(edition)).host
  end

  test 'returns public supporting page URL including host in production environment' do
    request.host = "whitehall.production.alphagov.co.uk"
    edition = create(:published_policy)
    supporting_page = create(:supporting_page, edition: edition)
    assert_equal "www.gov.uk", URI.parse(public_supporting_page_url(edition, supporting_page)).host
  end

  test 'returns public supporting page URL including host in public production environment' do
    request.host = "www.gov.uk"
    edition = create(:published_policy)
    supporting_page = create(:supporting_page, edition: edition)
    assert_equal "www.gov.uk", URI.parse(public_supporting_page_url(edition, supporting_page)).host
  end

  test 'returns public document URL including host in preview environment' do
    request.host = "whitehall.preview.alphagov.co.uk"
    edition = create(:published_policy)
    assert_equal "www.preview.alphagov.co.uk", URI.parse(public_document_url(edition)).host
  end

  test 'returns public document URL including host in public preview environment' do
    request.host = "www.preview.alphagov.co.uk"
    edition = create(:published_policy)
    assert_equal "www.preview.alphagov.co.uk", URI.parse(public_document_url(edition)).host
  end

  test 'returns public supporting page URL including host in preview environment' do
    request.host = "whitehall.preview.alphagov.co.uk"
    edition = create(:published_policy)
    supporting_page = create(:supporting_page, edition: edition)
    assert_equal "www.preview.alphagov.co.uk", URI.parse(public_supporting_page_url(edition, supporting_page)).host
  end

  test 'returns public supporting page URL including host in public preview environment' do
    request.host = "www.preview.alphagov.co.uk"
    edition = create(:published_policy)
    supporting_page = create(:supporting_page, edition: edition)
    assert_equal "www.preview.alphagov.co.uk", URI.parse(public_supporting_page_url(edition, supporting_page)).host
  end

  test 'returns public URL including host in preview admin environment' do
    request.host = 'whitehall-admin.preview.alphagov.co.uk'
    edition = create(:published_policy)
    supporting_page = create(:supporting_page, edition: edition)
    assert_equal "www.preview.alphagov.co.uk", URI.parse(public_supporting_page_url(edition, supporting_page)).host
  end

  test 'returns public URL including host in production admin environment' do
    request.host = 'whitehall-admin.production.alphagov.co.uk'
    edition = create(:published_policy)
    supporting_page = create(:supporting_page, edition: edition)
    assert_equal "www.gov.uk", URI.parse(public_supporting_page_url(edition, supporting_page)).host
  end
end
