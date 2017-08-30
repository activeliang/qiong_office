class ImportsController < ApplicationController

  def  index
    @imports = Import.all
  end

  def show
    @import = Import.find(params[:id])
  end

  def destroy
    @import = Import.find(params[:id])
    if @import.destroy
      redirect_to imports_path, alert: "已删除!"
    else
      redirect_to :back
    end
  end
end
