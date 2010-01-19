require_dependency 'comments'
require_dependency 'trial'

class Journal::PhotosController < ApplicationController
  include Comments
#  include Trial

  cache_sweeper :photo_sweeper, :only => [:new, :edit, :delete, :new_comment, :edit_comment, :delete_comment]
  cache_sweeper :rss_sweeper, :only => [:new, :edit, :delete]

  layout 'log'

  def index
    @buttons = write_permission?

    conditions = "user_id = #{log_owner.id}"
    conditions << " AND private = FALSE" unless write_permission?

    #Listar las ultimas fotos (paginar)
    @pages,  @photos = paginate(:photos,
                :per_page =>10,
                :conditions => conditions,
                :order => 'taken_on DESC, photos.created_at DESC', :include => [:tags])

    @cloud_tags = Photo.tags_count(:raw => true,
                                   :conditions => conditions,
                                   :limit => 100,
                                   :count => '>1',
                                   :order => 'tags.name ASC')
  end

  def search
    @buttons = write_permission?

    conditions = "user_id = #{log_owner.id}"
    conditions << " AND private = FALSE" unless write_permission?

    @tag = params[:tagged]
    @pages,  @photos = paginate(:photos, :tagged => @tag,
                :per_page =>10,
                :conditions => ["user_id = :user_id", {:user_id => log_owner.id}],
                :order => 'taken_on DESC, photos.created_at DESC', :include => [:tags])

    #no pueden volver ordenadas pq ordena por count para limit
    @cloud_tags = Photo.find_related_tags(@tag, :raw => true, :conditions => conditions, :limit => 20, :count => '>1')
    @cloud_tags.sort!{|a,b| a['name'] <=> b['name']}
  end

  def new
    if request.post?
      @photo = Photo.new(params[:photo])
      @photo.user = log_owner
      if @photo.save
        @photo.tag(params[:tags].downcase, {:separator => /[\s,;:]+/, :clear => true})
        flash[:notice] = "Photo uploaded succesfully"
        redirect_to :action => :index
      end
    else
      @photo = Photo.new
      @photo.private = log_owner.private_default
    end
  end

  def show
    @buttons = write_permission?
    @photo = get_object
    unless read_fragment(:action => 'show', :part => 'comments')
      @comments = @photo.users_comments.find(:all, :include => [:user])
    end

  end

  def edit
    @photo = get_object
    if request.post?
      if @photo.update_attributes(params[:photo])
        @photo.tag(params[:tags].downcase, {:separator => /[\s,;:]+/, :clear => true})
        flash[:notice] = "Photo updated succesfully"
        redirect_to :action => :index
      end
    end
  end

  def delete
    if request.post?
      get_object.destroy
      flash[:notice] = "Photo deleted."
    end
    redirect_to :action=>'index'
  end

##################################
private
##################################
  def get_object(*args)
    if args.size == 0
      @cached_photo ||= log_owner.photos.find(params[:id])
    else
      log_owner.photos.find(params[:id], *args)
    end
  end

  def valid_photo
    begin
    #Lanza una excepcin si la sesion no existe
      @photo = get_object
      if @photo.private && !write_permission?
        flash[:error] = 'Photo does not exist or is private.'
        redirect_to :action => 'index'
      end
    rescue
      flash[:error] = 'Photo does not exist. Probably has been deleted.'
      redirect_to :action => 'index'
    end
  end

  #Comprueba que se accede a un log que existe
  before_filter :valid_log_filter

  #Comprueba que la foto existe y est asociada con el log
  before_filter :valid_photo, :only => [:show, :edit, :delete]

  #Comprueba que el usuario actual es el dueo del log
  before_filter :write_permission_filter, :only => [:new, :edit, :delete]

end
