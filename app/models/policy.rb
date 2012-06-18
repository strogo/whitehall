class Policy < Edition
  include Edition::NationalApplicability
  include Edition::Topics
  include Edition::Ministers
  include Edition::FactCheckable
  include Edition::SupportingPages
  include Edition::Countries

  has_many :edition_relations, through: :document
  has_many :related_editions, through: :edition_relations, source: :edition
  has_many :published_related_editions, through: :edition_relations, source: :edition, conditions: {editions: {state: 'published'}}

  belongs_to :policy_team

  validates :summary, presence: true

  class Trait < Edition::Traits::Trait
    def process_associations_after_save(edition)
      edition.related_editions = @edition.related_editions
    end
  end

  add_trait Trait

  after_destroy :remove_edition_relations

  def self.stub
    where(stub: true)
  end

  def title_without_stub
    read_attribute(:title)
  end

  def title
    stub? ? "[Sample] #{title_without_stub}" : title_without_stub
  end

  def sluggable_title
    title_without_stub
  end

  def title_with_topics
    parts = [title]
    parts << "(#{topics.map(&:name).to_sentence})" if topics.any?
    parts.join(" ")
  end

  def has_summary?
    true
  end

  private

  def remove_edition_relations
    edition_relations.each(&:destroy)
  end
end
