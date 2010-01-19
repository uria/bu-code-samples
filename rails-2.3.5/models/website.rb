class Website < ActiveRecord::Base
  has_many :vouchers
  
  validates_presence_of :url
end
