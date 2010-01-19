class Journal::ReportsController < ApplicationController
  layout 'log', :only => :index

  def index
  end

  def training
  	@res = TrainingSession.historic(log_owner, params[:from], params[:to])
  end

  def bodystats
  	@res = BodyStat.historic(log_owner, params[:from], params[:to])
  end

  def intensity
  	@res = TrainingSession.intensityStack(log_owner, params[:from], params[:to])
  	puts @res
  end

  #Comprueba que se accede a un log que existe
  before_filter :valid_log_filter

end
