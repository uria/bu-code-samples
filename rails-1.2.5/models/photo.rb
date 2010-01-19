class Photo < ActiveRecord::Base
  belongs_to :user
  has_many :users_comments, :class_name => 'Comment', :as => :commentable, :order => 'comments.created_at ASC', :dependent => :delete_all

  file_column :image, :magick => {:versions => {"thumb" => "128x128>", "medium" => "720x540>" }}
  acts_as_taggable :join_table => 'tags_photos'

  validates_length_of :title, :within => 1..128, :allow_nil => false, :too_log => "too long, %d characters maximum.", :too_short => "can't be empty."
  validates_presence_of :user
  validates_presence_of :taken_on

  def validate
    if image.nil?
      errors.add(:image, "can't be empty")
    end
  end

end
