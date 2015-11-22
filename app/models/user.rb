class User < ActiveRecord::Base
	has_many :pieces
	has_many :games, :through => :pieces

	# Include default devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable,
	     :recoverable, :rememberable, :trackable, :validatable

	# This is part of STI ~AMP:
	delegate :pawns, :queens, :kings, :knights, :rooks, :bishops, to: :pieces
end
