# Sample schema:
#   create_table "users", :force => true do |t|
#     t.column "login",            :string, :limit => 40
#     t.column "email",            :string, :limit => 100
#     t.column "crypted_password", :string, :limit => 40
#     t.column "salt",             :string, :limit => 40
#     t.column "activation_code",  :string, :limit => 40 # only if you want
#     t.column "activated_at",     :datetime             # user activation
#     t.column "created_at",       :datetime
#     t.column "updated_at",       :datetime
#   end
#
# If you wish to have a mailer, run:
#
#   ./script/generate authenticated_mailer user
#
# Be sure to add the observer to the form login controller:
#
#   class AccountController < ActionController::Base
#     observer :user_observer
#   end
#
# For extra credit: keep these two requires for 2-way reversible encryption
# require 'openssl'
# require 'base64'
#
require 'digest/sha1'
require 'RMagick'

class User < ActiveRecord::Base
  has_one :user_profile, :dependent => true
  has_many :training_sessions
  has_many :exercises
  has_many :programs
  has_many :body_stats
  has_many :messages, :foreign_key => 'recipient_id', :order => 'sent_at DESC'
  has_and_belongs_to_many :buddies, :class_name => 'User' ,:join_table => 'user_buddies', :association_foreign_key => 'buddy_id'
  has_many :comments
  has_many :photos
  has_one :payment

  acts_as_taggable :join_table => 'tags_users'

  #file_column :avatar_image, :magick => {:crop => "1:1", :geometry => "64x64>"}
  file_column :avatar_image, :magick => {:transformation => Proc.new { |img| img.format == 'GIF' ? img : img.crop(::Magick::CenterGravity, [img.columns, img.rows].min, [img.columns, img.rows].min) },
                                         :geometry => "64x64>"}

  #########################################################
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 5..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login, :within => 3..16
  validates_format_of       :login, :with =>/^\w+$/, :message => "can only be composed of letters, digits and underscores"
  validates_exclusion_of    :login, :in => %w( admin superuser root administrator webmaster master www wiki help home ), :message => "invalid, choose other"
  validates_length_of       :email, :within => 6..100
  validates_format_of       :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "has invalid format"
  validates_uniqueness_of   :login, :email, :salt
  before_save :encrypt_password
  after_create :create_profile    #Each user has a profile

  # Uncomment this to use activation
  # before_create :make_activation_code

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    # use this instead if you want user activation
    # u = find :first, :select => 'id, salt', :conditions => ['login = ? and activated_at IS NOT NULL', login]
    u = find_by_login(login) # need to get the salt
    return nil unless u
    find :first, :conditions => ["id = ? AND crypted_password = ?", u.id, u.encrypt(password)]
  end

  def self.authenticate_from_cookie(login, crypted_password)
    find :first, :conditions => ["id = ? AND crypted_password = ?", login, crypted_password]
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def owns_exercise!(exercise_id)
    if exercises.find(exercise_id).nil?
      raise SecurityError, "Exercise does not belong to User"
    end
  end

  def buddy?(id)
    begin
      buddies.find(id)
      true
    rescue
      false
    end
  end

  #Adds a user to the buddies list of this user if it's not there already
  def add_buddy!(buddy_name)
    buddy = User.find(:first, :conditions => ["login = ?", buddy_name])
    if buddy
      if !buddy?(buddy.id)
        buddies.push_with_attributes(buddy, :friendship_at => Time.now)
      else
        raise "#{buddy.login} is already your buddy."
      end
    else
      raise "#{buddy_name} is not a username."
    end
  end

  def delete_buddy!(buddy_name)
    buddy = User.find(:first, :conditions => ["login = ?", buddy_name])
    if buddy && buddy?(buddy.id)
      buddies.delete(buddy)
    else
      raise "#{buddy_name} is not your buddy."
    end
  end

  def new_messages_count
    #messages.find(:all, :conditions => ['opened = false']).size
    Message.count(['recipient_id = ? AND opened = false', id]) #faster
  end

  def trial?
    kind == 2
  end

  #Promotes to paying status and saves. Returns
  def promote_to_paying_status
    self.kind = 3
    save
  end

###################
protected
###################
  # before filter
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
    crypted_password.blank? or not password.blank?
  end

  #Create a profile for this user. Member since today.
  def create_profile
    create_user_profile({'started_to_log_on' => Date.today})
  end

end
