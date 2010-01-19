class VouchersController < ApplicationController
  layout 'layout'
  
  def index
    @website = Website.find(params[:website_id], :include => [:vouchers])
  end

  def last_vouchers
    @vouchers = Voucher.find(:all, :order => "created_at DESC" ,:limit => 10)
  end
  
  def new
    @voucher = Voucher.new(params[:voucher])
  end
  
  def create
    @voucher = Voucher.new(params[:voucher])
    if @voucher.save
      redirect_to root_path
    else
      render :new
    end
  end

  def vote
    @voucher = Voucher.find(:first, params[:id])
    @voucher.votes.create(params[:vote].merge({:ip => request.remote_ip})) if @voucher
    render :nothing => true
  end
end
