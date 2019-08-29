# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_account!
  before_action :account_company_ids, unless: :devise_controller?

  def account_company_ids
    @account_company_ids = current_account.employees.pluck(:company_id).join(' ')
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name surname])
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[email])
  end

  def after_sign_up_path_for(resource)
    account_path(id: resource.id)
  end

  def after_sign_in_path_for(resource)
    account_path(id: resource.id)
  end

  def after_sign_out_path_for(_resourse)
    new_account_session_path
  end

  def current_ability
    @current_ability ||= ::Ability.new(current_account)
  end

  rescue_from CanCan::AccessDenied do |_exception|
    flash[:error] = 'Access denied.'
    redirect_to root_path
  end
end
