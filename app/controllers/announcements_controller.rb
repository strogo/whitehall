class AnnouncementsController < DocumentsController

  def index
    announced = AnnouncementsFilter.new(valid_types, params_filters)
    @results = announced.announcements
  end

  def show
    prefer_loading_views_for(@document.type)
    @related_policies = @document.published_related_policies
    @topics = @related_policies.map { |d| d.topics }.flatten.uniq
  end

  def document_class
    Announcement
  end

private

  def params_filters
    sanitized_filters(params.slice(:page, :type))
  end

  def valid_types
    %w[ news_article speech ]
  end

  def sanitized_filters(filters)
    filters.delete(:type) unless filters[:type].nil? || valid_types.include?(filters[:type].to_s)
    filters
  end

  def prefer_loading_views_for(document_type)
    _prefixes.insert(0, document_type.underscore.pluralize)
  end

  class AnnouncementsFilter
    def initialize(valid_types, options={})
      @valid_types, @options = valid_types, options
    end

    def valid_types
      @valid_types
    end

    def announcements
      @announcements ||= (
        announcements = Edition
        announcements = announcements.by_type(@options[:type] ? @options[:type].classify : valid_types.collect {|c| c.classify })
        announcements = announcements.published
        announcements = announcements.by_first_published_at
        announcements.includes(:organisations).page(@options[:page] || 1).per(20)
      )
    end
  end
end
