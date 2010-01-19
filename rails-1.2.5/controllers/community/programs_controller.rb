class Community::ProgramsController < ApplicationController
  layout 'community', :except => 'popular_programs'

  def index
    authorize_copy

    unless read_fragment(:controller => 'programs', :action => 'index')
      #Listar todos los programas (paginar)
      @pages,  @progs = paginate(:programs, :conditions => ['programs.parent_id IS NULL AND programs.created_at > ? AND programs.private = FALSE', 26.weeks.ago.to_formatted_s(:db)] ,:per_page =>15, :order => 'programs.created_at DESC', :include => [:user, :tags])
      #@pages,  @progs = paginate(:programs, :conditions => ['parent_id IS NULL'] ,:per_page =>15, :order => 'programs.created_at DESC', :include => :user)
      @cloud_tags = Program.tags_count(:raw => true, :limit => 100, :conditions => 'programs.private = FALSE', :count => '>1', :order => 'tags.name ASC')
    end
  end

  def search
    authorize_copy
    @tag = params[:tagged]
    @pages,  @progs = paginate(:programs, :tagged => params[:tagged], :per_page =>15, :conditions => 'private = FALSE', :order => 'programs.created_at DESC', :include => [:user, :tags])

    #no pueden volver ordenadas pq ordena por count para limit
    @cloud_tags = Program.find_related_tags(@tag, :raw => true, :conditions => 'private = FALSE', :limit => 20, :count => '>1')
    @cloud_tags.sort!{|a,b| a['name'] <=> b['name']}
  end

  def popular_programs
    authorize_copy

    since = 1.month.ago
    @programs = Program.find_by_sql(["select * from programs inner join (select parent_id as program, count(*) as children_count from programs where updated_at > ? group by parent_id order by children_count desc limit 10) as copied_programs on id = program", since.strftime('%Y-%m-%d')])
  end
end
