class Community::PhotosController < ApplicationController

layout 'community'

  def index
    #Listar todas las photos (paginar)
    unless read_fragment(:controller => 'photos', :action => 'index')
      @pages,  @photos = paginate(:photos, :conditions => ['photos.created_at > ? AND photos.private = FALSE', 12.months.ago.to_formatted_s(:db)] ,:per_page =>10, :order => 'photos.updated_at DESC', :include => [:user])
      @cloud_tags = Photo.tags_count(:raw => true, :conditions => 'photos.private = FALSE', :limit => 100, :count => '>1', :order => 'tags.name ASC')
    end
  end

  def search
    @tag = params[:tagged]
    @pages,  @photos = paginate(:photos, :tagged => params[:tagged], :conditions => 'private = FALSE', :per_page =>15, :order => 'photos.created_at DESC', :include => [:user, :tags])

    #no pueden volver ordenadas pq ordena por count para limit
    @cloud_tags = Photo.find_related_tags(@tag, :raw => true, :conditions => 'private = FALSE', :limit => 20, :count => '>1')
    @cloud_tags.sort!{|a,b| a['name'] <=> b['name']}
  end

end
