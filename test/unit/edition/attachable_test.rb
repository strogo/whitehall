require 'test_helper'

class Edition::AttachableTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess

  test "allows attachment" do
    assert build(:publication).allows_attachments?
  end

  test "should allow multiple attachments" do
    attachment_1 = create(:attachment)
    attachment_2 = create(:attachment)

    publication = create(:publication, attachments: [attachment_1, attachment_2])

    assert_equal [attachment_1, attachment_2], publication.attachments
  end

  test "should allow deletion of attachments via nested attributes" do
    attachment_1 = create(:attachment)
    attachment_2 = create(:attachment)

    publication = create(:publication, attachments: [attachment_1, attachment_2])

    edition_attachments_attributes = publication.edition_attachments.inject({}) do |h, da|
      h[da.id] = da.attributes.merge("_destroy" => (da.attachment == attachment_1 ? "1" : "0"))
      h
    end
    publication.update_attributes(edition_attachments_attributes: edition_attachments_attributes)
    publication.reload

    assert_equal [attachment_2], publication.attachments
  end

  test 'should say a edition does not have a thumbnail when it has no attachments' do
    edition = create(:publication)
    refute edition.has_thumbnail?
  end

  test 'should say a edition does not have a thumbnail when it has no thumbnailable attachments' do
    sample_csv = create(:attachment, file: fixture_file_upload('sample-from-excel.csv', 'text/csv'))

    edition = create(:publication)
    edition.attachments << sample_csv

    refute edition.has_thumbnail?
  end

  test 'should say a edition has a thumbnail when it has a thumbnailable attachment' do
    sample_csv = create(:attachment, file: fixture_file_upload('sample-from-excel.csv', 'text/csv'))
    greenpaper_pdf = create(:attachment, file: fixture_file_upload('greenpaper.pdf', 'application/pdf'))
    two_pages_pdf = create(:attachment, file: fixture_file_upload('two-pages.pdf'))

    edition = create(:publication)
    edition.attachments << sample_csv
    edition.attachments << greenpaper_pdf
    edition.attachments << two_pages_pdf

    assert edition.has_thumbnail?
  end

  test 'should return the URL of a thumbnail when the edition has a thumbnailable attachment' do
    sample_csv = create(:attachment, file: fixture_file_upload('sample-from-excel.csv', 'text/csv'))
    greenpaper_pdf = create(:attachment, file: fixture_file_upload('greenpaper.pdf', 'application/pdf'))
    two_pages_pdf = create(:attachment, file: fixture_file_upload('two-pages.pdf'))

    edition = create(:publication)
    edition.attachments << sample_csv
    edition.attachments << greenpaper_pdf
    edition.attachments << two_pages_pdf

    assert_equal greenpaper_pdf.url(:thumbnail), edition.thumbnail_url
  end

  test 'should include attachment titles into #indexable_content' do
    attachment = create(:attachment, title: "The title of the attachment")
    edition = create(:publication, body: "Document body.")
    edition.attachments << attachment

    assert_equal "Document body. Attachment: The title of the attachment", edition.indexable_content
  end

  test "#destroy should also remove the relationship to any attachments" do
    edition = create(:draft_publication, attachments: [create(:attachment)])
    relation = edition.edition_attachments.first
    edition.destroy
    refute EditionAttachment.find_by_id(relation.id)
  end
end
