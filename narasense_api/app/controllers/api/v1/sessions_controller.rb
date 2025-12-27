class Api::V1::SessionsController < Devise::SessionsController
  respond_to :json
  skip_before_action :verify_authenticity_token, only: :create

  # POST /api/v1/users/sign_in
  def create
    byebug
    # 1) Robustly extract credentials from multiple possible shapes
    creds = extract_credentials_from_params
    email    = creds[:email].to_s.strip
    password = creds[:password].to_s

    # 2) Try to find the user and verify password
    user = User.find_for_authentication(email: email)

    if user&.valid_password?(password)
      # 3) Sign in and respond with JSON (no HTML redirect)
      sign_in(:user, user)
      render json: {
        message: "Logged in successfully",
        user: {
          id: user.id,
          email: user.email,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      }, status: :ok
    else
      # 4) Clear any session and return unauthorized
      sign_out(:user) rescue nil
      render json: { message: "Login failed. Invalid email or password." }, status: :unauthorized
    end
  end

  # DELETE /api/v1/users/sign_out
  def destroy
    sign_out(:user)
    render json: { message: "Logged out" }, status: :ok
  end

  private

  # Accepts:
  #  { "user": { "email": "...", "password": "..." } }
  #  { "session": { "user": { "email": "...", "password": "..." } } }
  #  or raw top-level { "email": "...", "password": "..." }
  def extract_credentials_from_params
    # prefer params[:user]
    if params[:user].present? && params[:user].is_a?(ActionController::Parameters)
      return params.require(:user).permit(:email, :password).to_h.symbolize_keys
    end

    # handle params like: { "session" => { "user" => { ... } } }
    if params[:session].present?
      sess = params[:session]
      if sess[:user].present?
        return ActionController::Parameters.new(sess[:user]).permit(:email, :password).to_h.symbolize_keys
      end
      # maybe session holds direct keys
      return ActionController::Parameters.new(sess).permit(:email, :password).to_h.symbolize_keys
    end

    # fallback: top-level keys
    if params[:email].present? || params[:password].present?
      return ActionController::Parameters.new(params.to_unsafe_h).permit(:email, :password).to_h.symbolize_keys
    end

    # extra fallback: try parsing raw JSON body
    begin
      raw = request.raw_post.presence && JSON.parse(request.raw_post) rescue nil
      if raw.is_a?(Hash)
        if raw['user'].is_a?(Hash)
          return ActionController::Parameters.new(raw['user']).permit(:email, :password).to_h.symbolize_keys
        elsif raw['session'].is_a?(Hash) && raw['session']['user'].is_a?(Hash)
          return ActionController::Parameters.new(raw['session']['user']).permit(:email, :password).to_h.symbolize_keys
        else
          return ActionController::Parameters.new(raw).permit(:email, :password).to_h.symbolize_keys
        end
      end
    rescue => _e
      # ignore parse errors
    end

    {}.with_indifferent_access
  end
end
