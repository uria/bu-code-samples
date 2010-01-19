class Message < ActiveRecord::Base
	belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
	belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"

	validates_presence_of :sender
	validates_presence_of :recipient, :message => "is not valid"
	validates_length_of :subject, :maximum => 128

	before_create do |m|
		m.opened= false
		m.sent_at= Time.now
  end
end
