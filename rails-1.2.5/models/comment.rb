class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :commentable, :counter_cache => :users_comments_count, :polymorphic => true

  acts_as_paranoid

  validates_length_of :name, :maximum => 64, :allow_nil => true
  validates_presence_of :content

  def validate
    if user.nil? && (name.nil? || name.size ==0)
      errors.add(:name, "can't be empty")
    end
  end

  def anonymous?
    user.nil?
  end
end
