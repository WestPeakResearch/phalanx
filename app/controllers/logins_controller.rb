class LoginsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create, :show]

  def new
  end

  def create
    user = User.find_by(email: params[:email]) # Restrict search to confirmed users to prevent spam.

    if user.present?
      token = user.generate_token_for(:magic_login)
      puts "url: #{login_with_token_url(token: token)}"
    end

    redirect_to new_login_path, notice: "Magic link sent"
  end

  def show
    user = User.find_by_token_for(:magic_login, params[:token])

    if user.present?
      sign_in(user) # This will invalidate the token by updating `last_sign_in_at`.

      redirect_to root_path, notice: "Signed in"
    else
      redirect_to new_login_path, flash: { alert: "Cannot authenticate" }
    end
  end

  def destroy
    sign_out
    redirect_to root_path, notice: "Signed out"
  end
end
