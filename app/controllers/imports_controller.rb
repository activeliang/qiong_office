class ImportsController < ApplicationController
  before_action :admin_required
  before_action :find_import, only: [:show, :destroy]
  def  index
    @imports = Import.all
  end

  def show
  end

  def destroy
    if @import.destroy
      redirect_to imports_path, alert: "已删除!"
    else
      redirect_to :back
    end
  end

  private
  def find_import
    @import = Import.find(params[:id])
  end
end
