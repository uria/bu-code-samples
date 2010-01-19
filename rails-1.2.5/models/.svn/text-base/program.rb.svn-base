class Program < ActiveRecord::Base
  belongs_to :user
  #has_many :program_sessions, :dependent => :destroy, :order => 'pos ASC'
  #Se quita el :dependent => :destroy pq al ser paranoid los programas no son autenticamente borrados
  has_many :program_sessions, :order => 'pos ASC'
  has_many :training_sessions
  has_many :users_comments, :class_name => 'Comment', :as => :commentable, :order => 'comments.created_at ASC', :dependent => :delete_all

  has_many :children, :class_name => 'Program', :foreign_key => 'parent_id', :dependent => :nullify
  belongs_to :parent, :class_name => 'Program', :foreign_key => 'parend_id'

#  acts_as_tree
  acts_as_paranoid
  acts_as_taggable :join_table => 'tags_programs'

  validates_length_of :title, :maximum => 64
  validates_presence_of :title
end
