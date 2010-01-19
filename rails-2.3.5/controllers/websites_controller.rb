class WebsitesController < ApplicationController
  layout 'layout'
  protect_from_forgery :only => []
    
  def search
    @websites = Website.url_like(params[:q])    
    redirect_to website_vouchers_url(@websites[0]) if @websites.length == 1
  end
end
