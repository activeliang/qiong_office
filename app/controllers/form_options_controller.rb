class FormOptionsController < ApplicationController
  def index
    @form_options = FormOption.all
    @form_option = FormOption.new
  end

  def create
    @form_option = FormOption.new(form_option_params)
    if @form_option.save
      redirect_to :back, notice: "新增成功"
    else
      redirect_to :back, alert: "新增失败！，检查：第一个输入框为空或者内容已存在！"
    end
  end

  def update
    @form_option = FormOption.find(params[:id])
    if @form_option.content.split('&').include?(params[:content])
      redirect_to :back, alert: "您添加的【#{params[:content]}】已存在，不要重复增加哦！"
    else

        if @form_option.content.empty?
          @form_option.content = @form_option.content << params[:content]
        else
          @form_option.content = @form_option.content << "&" << params[:content]
        end
        if @form_option.save
          redirect_to :back, notice: "新增成功！"
        else
          redirect_to :back, alert: "新增失败！"
        end

    end
  end

  def delete_item
    form_option = FormOption.find(params[:id])
    new_record = form_option.content.split('&')
    new_record.delete(params[:item])
    form_option.content = new_record.join("&")
    if form_option.save
      redirect_to form_options_path, notice: "成功删除！"
    else
      redirect_to :back, alert: "删除失败！"
    end
  end

  private
  def form_option_params
    params.require(:form_option).permit(:field, :content)
  end
end
