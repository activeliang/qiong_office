class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def admin_required
    if !current_user
      redirect_to :back, alert: "请先登录管理员账号~"
    else
      if !current_user.admin?
        redirect_to "/", alert: "你不是管理员哦~"
      end
    end
  end
end
