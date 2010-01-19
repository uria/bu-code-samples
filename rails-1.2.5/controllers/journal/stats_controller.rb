require_dependency 'unit_conversion'
require_dependency 'trial'

class Journal::StatsController < ApplicationController
  include UnitConversion
#  include Trial

  layout 'log', :except =>[:pdf]

  def index
    @buttons = write_permission?

    conditions = "user_id = #{log_owner.id}"
    conditions << " AND private = FALSE" unless write_permission?

    @pages,  @bs = paginate(:body_stats,
              :per_page =>15,
              :conditions => conditions,
              :order => 'measured_on DESC, id DESC')
  end

  def new
    unless request.post?
      @bodystat = BodyStat.new
      @bodystat.private = log_owner.private_default
      @register_bodyfat = false;
    else
      @bodystat = BodyStat.new(params[:bodystat])
      @bodystat.bodyweight = params[:bodyweight]
      @register_bodyfat = (params[:register_bodyfat]?true:false);
      @bodystat.user = log_owner
      if @bodystat.save
        redirect_to :action => 'index'
         flash[:notice] = "Body stats. entry saved."
      end
    end
  end

  def edit
    unless request.post?
      @bodystat = get_stat
      @register_bodyfat = !@bodystat.bodyfat.nil?;
      render :action => 'new'
    else
      @bodystat = get_stat
      @bodystat.bodyweight = params[:bodyweight]
      @register_bodyfat = (params[:register_bodyfat]?true:false);
      if @bodystat.update_attributes(params[:bodystat])
        flash[:notice] = "Body stats. entry modified."
        redirect_to :action => 'index'
      else
        render :action => 'new'
      end
    end
  end

  def delete
    if request.post?
      get_stat.destroy
    end
    flash[:notice] = "Body stats. entry deleted."
    redirect_to :action=>'index'
  end

  def export
    if request.post?
      from = Time.gm(params[:date]["from(1i)"],params[:date]["from(2i)"],params[:date]["from(3i)"])
      to = Time.gm(params[:date]["to(1i)"],params[:date]["to(2i)"],params[:date]["to(3i)"])
      @filename = log_owner.login + "_body_stats";

      conditions = "measured_on >= #{from.to_formatted_s(:db)} AND measured_on <= #{to.to_formatted_s(:db)}"
      conditions << " AND private = FALSE" unless write_permission?

      @stats = log_owner.body_stats.find(:all, :conditions => ["measured_on>=? AND measured_on<=?", from, to], :order => "measured_on ASC")
      if @stats.length == 0
        flash[:warning] = "No bodystats within selected dates."
      elsif  params[:export][:format] == 'PDF'
        render :partial => "pdf"
      else
        response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
        response.headers['Content-Disposition'] = "attachment; filename=#{@filename}.csv"
        render :partial => "csv"
      end
    end
  end

private

  def stats_to_pdf(stats, filename)
    _pdf = PDF::Writer.new
    _pdf.margins_in 0.6, 1, 0.6, 1
    _pdf.select_font "Helvetica"

    PDF::SimpleTable.new do |tab|
      tab.column_order.push(*%w(measured_on bw bf))

      tab.columns["measured_on"] = PDF::SimpleTable::Column.new("measured_on") { |col|
        col.heading = "Measured on"
      }
      tab.columns["bw"] = PDF::SimpleTable::Column.new("bw") { |col|
        col.heading = "Bodyweight"
        col.justification = :right
      }
      tab.columns["bf"] = PDF::SimpleTable::Column.new("bf") { |col|
        col.heading = "Bodyfat"
        col.justification = :right
      }

      tab.show_lines    = :all
      tab.show_headings = true
      tab.orientation   = :center
      tab.position      = :center

      data = Array.new
      stats.each { |s|  data << {"measured_on" => s.measured_on, "bw" => s.bodyweight, "bf" =>s.bodyfat} }
      tab.data.replace data
      tab.render_on(_pdf)
    end

    filename = filename.gsub(/\s|-|\/\]/, '_')
    filename = filename.gsub(/[^0-9a-zA-Z_]/, '')

    send_data _pdf.render, :filename => filename+".pdf", :type => "application/pdf"
  end

  def get_stat
    @stat ||=log_owner.body_stats.find(params[:id])
  end

  def valid_stat
    begin
      log_owner.body_stats.find(params[:id])
    rescue
      flash[:notice] = "Invalid body stat"
      redirect_to :action => 'index'
    end
  end

  def unit_conversion
    begin
      params[:bodyweight] = weight_string_to_f(params[:bodyweight]) if params[:bodyweight]
      params[:bodystat][:bodyfat] = (params[:register_bodyfat] ? params[:bodystat][:bodyfat].gsub("%", "") : nil)
    rescue
    end
  end

  before_filter :valid_log_filter
  before_filter :valid_stat, :only =>[:edit, :delete]
  before_filter :unit_conversion, :only => [:new, :edit]
  before_filter :write_permission_filter, :only =>[:new, :edit, :delete]
end
