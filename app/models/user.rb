class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :validatable, :trackable

  has_many :initial_reviews, dependent: :nullify

  generates_token_for :magic_login, expires_in: 15.minutes do
    # The magic_login token will expire every time the user signs in.
    last_sign_in_at
  end

  def password_required?
    false
  end
end
