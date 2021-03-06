class SupportingPageSearchIndexObserver < ActiveRecord::Observer
  observe :policy # observe :edition doesn't work

  def after_publish(edition)
    edition.supporting_pages.each(&:update_in_search_index)
  end

  def after_archive(edition)
    edition.supporting_pages.each(&:remove_from_search_index)
  end
end
