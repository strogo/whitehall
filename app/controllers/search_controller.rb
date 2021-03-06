class SearchController < PublicFacingController
  def index
    @search_term = params[:q]
    if @search_term.present?
      @results = Whitehall.search_client.search(@search_term)
      render action: :results
    end
  end

  def autocomplete
    render text: Whitehall.search_client.autocomplete(params[:q])
  end
end