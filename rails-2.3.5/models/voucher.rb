class Voucher < ActiveRecord::Base
  belongs_to :website
  has_many :votes

  attr_accessor :website_domain

  validates_presence_of :voucher
  validates_format_of   :website_domain, :with => /^(http:\/\/)?([^\/]+\.[^\/]+)\/?/i

  before_save :save_website

  def website_domain=(uri)
    domain = /^(http:\/\/)?([^\/]+\.[^\/]+)\/?/.match(uri.downcase)
    if domain
      @website_domain = domain[2]
    else
      @website_domain = uri
    end
  end

  private

  def save_website
    self.website = Website.find_or_create_by_url(website_domain)
  end
end

