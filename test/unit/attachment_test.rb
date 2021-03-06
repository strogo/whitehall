require 'test_helper'

class AttachmentTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess

  setup do
    AttachmentUploader.enable_processing = true
  end

  teardown do
    AttachmentUploader.enable_processing = false
  end

  test 'should be invalid without a title' do
    attachment = build(:attachment, title: nil)
    refute attachment.valid?
  end

  test 'should be invalid without a file' do
    attachment = build(:attachment, file: nil)
    refute attachment.valid?
  end

  test 'should be valid without ISBN' do
    attachment = build(:attachment, isbn: nil)
    assert attachment.valid?
  end

  test 'should be valid with blank ISBN' do
    attachment = build(:attachment, isbn: "")
    assert attachment.valid?
  end

  test "should be invalid with an ISBN that's not in ISBN-10 or ISBN-13 format" do
    attachment = build(:attachment, isbn: "invalid-isbn")
    refute attachment.valid?
  end

  test 'should be valid with ISBN in ISBN-10 format' do
    attachment = build(:attachment, isbn: "0261102737")
    assert attachment.valid?
  end

  test 'should be valid with ISBN in ISBN-13 format' do
    attachment = build(:attachment, isbn: "978-0261103207")
    assert attachment.valid?
  end

  test "should be valid without Command paper number" do
    attachment = build(:attachment, command_paper_number: nil)
    assert attachment.valid?
  end

  test "should be valid with blank Command paper number" do
    attachment = build(:attachment, command_paper_number: '')
    assert attachment.valid?
  end

  ['C.', 'Cd.', 'Cmd.', 'Cmnd.', 'Cm.'].each do |prefix|
    test "should be valid when the Command paper number starts with '#{prefix}'" do
      attachment = build(:attachment, command_paper_number: "#{prefix} 1234")
      assert attachment.valid?
    end
  end

  test "should be invalid when the command paper number starts with an unrecognised prefix" do
    attachment = build(:attachment, command_paper_number: "NA 1234")
    refute attachment.valid?
    expected_message = "is invalid. The number must start with one of #{Attachment::VALID_COMMAND_PAPER_NUMBER_PREFIXES.join(', ')}"
    assert attachment.errors[:command_paper_number].include?(expected_message)
  end

  test 'should be invalid with malformed order url' do
    attachment = build(:attachment, order_url: "invalid-url")
    refute attachment.valid?
  end

  test 'should be valid with order url with HTTP protocol' do
    attachment = build(:attachment, order_url: "http://example.com")
    assert attachment.valid?
  end

  test 'should be valid with order url with HTTPS protocol' do
    attachment = build(:attachment, order_url: "https://example.com")
    assert attachment.valid?
  end

  test 'should be valid without order url' do
    attachment = build(:attachment, order_url: nil)
    assert attachment.valid?
  end

  test 'should be valid with blank order url' do
    attachment = build(:attachment, order_url: nil)
    assert attachment.valid?
  end

  test 'should be valid if the price is nil' do
    attachment = build(:attachment, price: nil)
    assert attachment.valid?
  end

  test 'should be valid if the price is blank' do
    attachment = build(:attachment, price: '')
    assert attachment.valid?
  end

  test 'should be valid if the price appears to be in whole pounds' do
    attachment = build(:attachment, price: "9", order_url: 'http://example.com')
    assert attachment.valid?
  end

  test 'should be valid if the price is in pounds and pence' do
    attachment = build(:attachment, price: "1.23", order_url: 'http://example.com')
    assert attachment.valid?
  end

  test 'should be invalid if the price is non numeric' do
    attachment = build(:attachment, price: 'free', order_url: 'http://example.com')
    refute attachment.valid?
  end

  test 'should be invalid if the price is zero' do
    attachment = build(:attachment, price: "0", order_url: 'http://example.com')
    refute attachment.valid?
  end

  test 'should be invalid if the price is less than zero' do
    attachment = build(:attachment, price: "-1.23", order_url: 'http://example.com')
    refute attachment.valid?
  end

  test 'should be invalid if a price is entered without an order url' do
    attachment = build(:attachment, price: "1.23")
    refute attachment.valid?
  end

  test 'should return filename even after reloading' do
    attachment = create(:attachment)
    refute_nil attachment.filename
    assert_equal attachment.filename, Attachment.find(attachment.id).filename
  end

  test "should save content type and file size on create" do
    greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
    attachment = create(:attachment, file: greenpaper_pdf)
    attachment.reload
    assert_equal "greenpaper.pdf", attachment.filename
    assert_equal "application/pdf", attachment.content_type
    assert_equal greenpaper_pdf.size, attachment.file_size
  end

  test "should save content type and file size on update" do
    greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
    whitepaper_pdf = fixture_file_upload('whitepaper.pdf', 'application/pdf')
    attachment = create(:attachment, file: greenpaper_pdf)
    attachment.update_attributes!(file: whitepaper_pdf)
    attachment.reload
    assert_equal "whitepaper.pdf", attachment.filename
    assert_equal "application/pdf", attachment.content_type
    assert_equal whitepaper_pdf.size, attachment.file_size
  end

  test "should set content type based on file extension when browser supplies octet-stream content type" do
    greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/octet-stream')
    attachment = create(:attachment, file: greenpaper_pdf)
    attachment.reload
    assert_equal "application/pdf", attachment.content_type
  end

  test "should set content type based on file extension when browser supplies no content type" do
    greenpaper_pdf = fixture_file_upload('greenpaper.pdf', nil)
    attachment = create(:attachment, file: greenpaper_pdf)
    attachment.reload
    assert_equal "application/pdf", attachment.content_type
  end

  test "should set page count for PDF on create" do
    two_pages_pdf = fixture_file_upload('two-pages.pdf')
    attachment = create(:attachment, file: two_pages_pdf)
    attachment.reload
    assert_equal 2, attachment.number_of_pages
  end

  test "should set page count for PDF on update" do
    two_pages_pdf = fixture_file_upload('two-pages.pdf')
    three_pages_pdf = fixture_file_upload('three-pages.pdf')
    attachment = create(:attachment, file: two_pages_pdf)
    attachment.update_attributes!(file: three_pages_pdf)
    attachment.reload
    assert_equal 3, attachment.number_of_pages
  end

  test "should save attachment even if parsing the PDF raises an exception" do
    greenpaper_pdf = fixture_file_upload('greenpaper.pdf')
    PDF::Reader.stubs(:new).raises
    assert_nothing_raised { create(:attachment, file: greenpaper_pdf) }
  end

  test "should allow CSV file types as attachments" do
    sample_from_excel_csv = fixture_file_upload('sample-from-excel.csv')
    attachment = create(:attachment, file: sample_from_excel_csv)
    attachment.reload
    assert_equal "text/csv", attachment.content_type
  end

  test "should not set page count for non-PDF" do
    sample_from_excel_csv = fixture_file_upload('sample-from-excel.csv')
    attachment = create(:attachment, file: sample_from_excel_csv)
    attachment.reload
    assert_nil attachment.number_of_pages
  end

  test "should be a PDF if underlying content type is application/pdf" do
    greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
    attachment = create(:attachment, file: greenpaper_pdf)
    attachment.reload
    assert attachment.pdf?
  end

  test "should not be a PDF if underlying content type is not application/pdf" do
    sample_csv = fixture_file_upload('sample-from-excel.csv', 'text/csv')
    attachment = create(:attachment, file: sample_csv)
    attachment.reload
    refute attachment.pdf?
  end

  test "should return the url to a PNG for PDF thumbnails" do
    greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
    attachment = create(:attachment, file: greenpaper_pdf)
    attachment.reload
    assert attachment.url(:thumbnail).ends_with?("thumbnail_greenpaper.pdf.png"), "unexpected url ending: #{attachment.url(:thumbnail)}"
  end

  test "should successfully create PNG thumbnail from the file_cache after a validation failure" do
    greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
    attachment = build(:attachment, title: nil, file: greenpaper_pdf)
    refute attachment.valid?
    second_attempt_attachment = build(:attachment, title: "title", file: nil, file_cache: attachment.file_cache)
    assert second_attempt_attachment.save
    type = `file -b --mime-type "#{second_attempt_attachment.file.thumbnail.path}"`
    assert_equal "image/png", type.strip
  end

  test "should return nil file extension when no uploader present" do
    attachment = build(:attachment)
    attachment.stubs(file: nil)
    assert_nil attachment.file_extension
  end

  test "should return nil file extension when uploader url not present" do
    attachment = build(:attachment)
    attachment.stubs(file: stub("uploader", url: nil))
    assert_nil attachment.file_extension
  end

  test "should return file extension if URL present but file empty" do
    attachment = build(:attachment)
    attachment.stubs(file: stub("uploader", empty?: true, url: "greenpaper.pdf"))
    assert_equal "pdf", attachment.file_extension
  end

  test "should return file extension if file present" do
    greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
    attachment = build(:attachment, file: greenpaper_pdf)
    assert_equal "pdf", attachment.file_extension
  end

  test "should save the price as price_in_pence" do
    attachment = create(:attachment, price: "1.23", order_url: 'http://example.com')
    attachment.reload
    assert_equal 123, attachment.price_in_pence
  end

  test "should save the price as nil if an existing price_in_pence is being reset to blank" do
    attachment = create(:attachment, price_in_pence: 999, order_url: 'http://example.com')
    attachment.price = ''
    attachment.save!
    attachment.reload
    assert_equal nil, attachment.price_in_pence
  end

  test "should not save a nil price as a zero price_in_pence" do
    attachment = create(:attachment, price: nil)
    attachment.reload
    assert_equal nil, attachment.price_in_pence
  end

  test "should not save a blank price as a zero price_in_pence" do
    attachment = create(:attachment, price: '')
    attachment.reload
    assert_equal nil, attachment.price_in_pence
  end

  test "should prefer the memoized price over price_in_pence" do
    attachment = build(:attachment, price: "1.23", price_in_pence: 345)
    assert_equal "1.23", attachment.price
  end

  test "should convert price_in_pence to price in pounds when a new price hasn't been set" do
    attachment = build(:attachment, price_in_pence: 345)
    assert_equal 3.45, attachment.price
  end

  test "should return nil if neither price nor price_in_pence are set" do
    attachment = build(:attachment, price: nil, price_in_pence: nil)
    assert_nil attachment.price
  end
end