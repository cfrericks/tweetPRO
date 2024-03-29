class User < ActiveRecord::Base
  attr_accessible :name, :email, :password, :password_confirmation, :avatar
  has_secure_password
  #paperclip info
  has_attached_file :avatar, :styles => { :medium => "135x135>", :thumb => "60x60>" }, :default_url => "/images/:style/missing.png"
  has_many :microposts, :dependent => :destroy
  has_many :relationships, :foreign_key =>  "follower_id", :dependent => :destroy
  has_many :followed_users, :through => :relationships, :source => :followed
  has_many :reverse_relationships, :foreign_key =>  "followed_id",
                                   :class_name =>   "Relationship",
                                   :dependent =>    :destroy
  has_many :followers, :through => :reverse_relationships, :source => :follower

  before_save { |user| user.email = email.downcase }
  before_save :create_remember_token

  validates :name,  :presence => true, :length => { :maximum => 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, :presence => true, :format => { :with => VALID_EMAIL_REGEX },
                    :uniqueness => { :case_sensitive => false }
  validates :password, :length => { :minimum => 6 }
  validates :password_confirmation, :presence => true

  def feed
    Micropost.from_users_followed_by(self)
  end

  def following?(other_user)
    relationships.find_by_followed_id(other_user.id)
  end

  def follow!(other_user)
    relationships.create!(:followed_id => other_user.id)
  end

  def unfollow!(other_user)
    relationships.find_by_followed_id(other_user.id).destroy
  end

  private

    def create_remember_token
      self.remember_token = SecureRandom.base64(10)
    end
end