class AbnormalsController < ApplicationController
  before_action :find_abnormal, only: [:destroy, :edit, :update]

  def  index
    @dia_url = "http://www.diastarasia.com/Diastar/Envelop.do?action=searchEnvelop"
    @abnormals = Abnormal.all
    respond_to do |format|
      format.xlsx{

        @abnormals.each do |r|

          #判断图片是否存在
          if r.image.present?
            get_image_url = r.image.thumb.url + '?imageslim'
          else
            get_image_url = "http://olmrxx9ks.bkt.clouddn.com/2017-08-19-%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202017-08-19%20%E4%B8%8B%E5%8D%885.51.10.png" + '?imageslim'
          end

          #把图片下载回本地
          unless File.exist?("#{Rails.root}/public/images/#{r.envelop}.png")
            data=open(get_image_url){|f|f.read}
            open("#{Rails.root}/public/images/#{r.envelop}.png","wb"){|f|f.write(data)}
          end
        end
      }

      format.html
    end
  end

  def new
    @abnormal = Abnormal.new
    option_1 = FormOption.where(:field => "负责人").first
    option_2 = FormOption.where(:field => "部门").first

    @principal_option = option_1.content.split('&') if option_1
    @department_option = option_2.content.split('&') if option_2
  end

  def create
    @abnormal = Abnormal.new(abnormal_params)
    @abnormal.envelop = params[:abnormal][:envelop].gsub(/\s/, '')
    if @abnormal.save
      GetEnvelopDetailJob.perform_later(@abnormal.id)
      CheckFormFieldJob.perform_later(params[:abnormal][:principal], params[:abnormal][:department])
      redirect_to abnormals_path, notice: "success!存入成功！"
    else
      render :new, alert: "请输入6位数的制工袋~"
    end
  end

  def edit
    @principal_option = FormOption.where(:field => "负责人").first.content.split('&')
    @department_option = FormOption.where(:field => "部门").first.content.split('&')
  end

  def update
    envelop = @abnormal.envelop
    if @abnormal.update(abnormal_params)
      GetEnvelopDetailJob.perform_later(@abnormal.id) if envelop != params[:abnormal][:envelop]
      redirect_to abnormals_path, notice: "编辑成功！"
    else
      render :edit, alert: "编辑失败！"
    end
  end

  def download_excel
    data=open("#{root_url(format: "xlsx")}"){|f|f.read}
    time = Time.now.strftime("%m-%d %H:%M")
    open("#{Rails.root}/public/office/#{time}.xlsx","wb"){|f|f.write(data)}
    render :json => { :status => "success", :download_url => "#{root_url}office/#{time}.xlsx" }
  end

  def destroy
    if @abnormal.destroy
      redirect_to abnormals_path, alert: "已删除！"
    end
  end

  private
  def abnormal_params
    params.require(:abnormal).permit(:envelop, :principal, :image, :reason, :faulter, :new_delivery, :department, :remarks, :input_time, :client, :model_no, :quantity, :raw_delivery, :merchandiser)
  end

  def find_abnormal
    @abnormal = Abnormal.find(params[:id])
  end
end
