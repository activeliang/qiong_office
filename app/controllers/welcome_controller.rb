class WelcomeController < ApplicationController

  def index
    b = []
    Abnormal.all.map{|a| b << a.reason }
    @r = b.join("&").html_safe
  end
end
