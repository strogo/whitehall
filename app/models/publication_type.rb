require 'active_record_like_interface'
require 'active_support/core_ext/object/blank.rb'
require 'active_support/core_ext/string/inflections.rb'

class PublicationType
  include ActiveRecordLikeInterface

  attr_accessor :id, :singular_name, :plural_name, :prevalence

  def slug
    name.downcase.gsub(/[^a-z]+/, "-")
  end

  def self.by_prevalence
    all.group_by { |pt| pt.prevalence }
  end

  def self.primary
    by_prevalence[:primary]
  end

  def self.less_common
    by_prevalence[:less_common]
  end

  def self.use_discouraged
    by_prevalence[:discouraged]
  end

  def self.migration
    by_prevalence[:migration]
  end

  PolicyPaper            = create(id: 1, singular_name: "Policy paper", plural_name: "Policy papers", prevalence: :primary)
  ImpactAssessment       = create(id: 2, singular_name: "Impact assessment", plural_name: "Impact assessments", prevalence: :primary)
  Guidance               = create(id: 3, singular_name: "Guidance", plural_name: "Guidance", prevalence: :primary)
  Form                   = create(id: 4, singular_name: "Form", plural_name: "Forms", prevalence: :primary)
  Statistics             = create(id: 5, singular_name: "Statistics", plural_name: "Statistics", prevalence: :primary)
  NationalStatistics     = create(id: 15, singular_name: "Statistics - national statistics", plural_name: "Statistics - national statistics", prevalence: :primary)
  ResearchAndAnalysis    = create(id: 6, singular_name: "Research and analysis", plural_name: "Research and analysis", prevalence: :primary)
  CorporateReport        = create(id: 7, singular_name: "Corporate report", plural_name: "Corporate reports", prevalence: :primary)

  # Less common
  TransparencyData       = create(id: 10, singular_name: "Transparency data", prevalence: :less_common)
  Treaty                 = create(id: 11, singular_name: "Treaty", plural_name: "Treaties", prevalence: :less_common)
  FoiRelease             = create(id: 12, singular_name: "FOI release", plural_name: "FOI releases", prevalence: :less_common)
  IndependentReport      = create(id: 14, singular_name: "Independent report", plural_name: "Independent reports", prevalence: :less_common)

  # Use is discouraged
  CircularNewsletterOrBulletin =
                           create(id: 8 , singular_name: "Circular, newsletter or bulletin", plural_name: "Circulars, newsletters and bulletins", prevalence: :discouraged)
  OfficialLetterOrNotice = create(id: 9 , singular_name: "Official letter or notice", plural_name: "Official letters and notices", prevalence: :discouraged)
  PromotionalMaterial    = create(id: 13, singular_name: "Promotional material", plural_name: "Promotional material", prevalence: :discouraged)

  # Temporary to allow migration
  Unknown                = create(id: 999, singular_name: "Publication", plural_name: "Publication", prevalence: :migration)
end
