class AbnormalsController < ApplicationController
  before_action :find_abnormal, only: [:destroy, :edit, :update]

  def  index
    @envelop_link = "http://www.diastarasia.com/Diastar/Envelop.do?action=searchEnvelop&envelopID="
    @model_no_link = "http://www.diastarasia.com/Diastar/ModelNo.do?action=searchModelNo&SearchBy=ByModelNo&modelNo="
    @abnormals = Abnormal.all
    respond_to do |format|
      format.xlsx{

        @abnormals.each do |r|

          #判断图片是否存在
          if r.image.present?
            get_image_url = r.image.thumb.url  '?imageslim'
          else
            get_image_url = "http://olmrxx9ks.bkt.clouddn.com/2017-08-19-%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202017-08-19%20%E4%B8%8B%E5%8D%885.51.10.png"  '?imageslim'
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
    option_3 = FormOption.where(:field => "处理方式").first

    @principal_option = option_1.content.split('&') if option_1
    @department_option = option_2.content.split('&') if option_2
    @deal_method_option = option_3.content.split('&') if option_3
  end

  def create
    @abnormal = Abnormal.new(abnormal_params)
    @abnormal.envelop = params[:abnormal][:envelop].gsub(/\s/, '')
    @abnormal.model_no = params[:abnormal][:model_no].gsub(/\s/, '')
    @abnormal.department = params[:abnormal][:department].join('&')
    @abnormal.faulter = params[:abnormal][:faulter].split(' ').join('&')
    @abnormal.deal_method = params[:abnormal][:deal_method].join('&')
    if @abnormal.save

      if @abnormal.envelop.present?
        GetEnvelopDetailJob.perform_later(@abnormal.id)
      elsif @abnormal.model_no.present?
        GetModelNoDetailJob.perform_later(@abnormal.id)
      end

      CheckFormFieldJob.perform_later(params[:abnormal][:principal], params[:abnormal][:department], params[:abnormal][:deal_method])
      redirect_to abnormals_path, notice: "success!存入成功！"

    else
      binding.pry
      render :new
    end
  end

  def edit
    @principal_option = FormOption.where(:field => "负责人").first.content.split('&')
    @department_option = FormOption.where(:field => "部门").first.content.split('&')
    @deal_method_option = FormOption.where(:field => "处理方式").first.content.split('&')
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
    time = Time.now.in_time_zone(8).strftime("%m-%d %H:%M")
    open("#{Rails.root}/public/office/#{time}.xlsx","wb"){|f|f.write(data)}
    render :json => { :status => "success", :download_url => "#{root_url}office/#{time}.xlsx" }
  end

  def destroy
    if @abnormal.destroy
      redirect_to abnormals_path, alert: "已删除！"
    end
  end





    def import
    csv_string = params[:csv_file].read.force_encoding('utf-8')

    success = 0
    failed = 0
    require 'csv'
    import = Import.create
      CSV.parse(csv_string)[1 .. -1].each do |row|
        if row[9].present?
          # binding.pry
          abnormal = import.abnormals.new( :input_time => row[0].to_s.sub(/日/, '').to_s.gsub(/(年|月)/, '-'),
                                   :client => row[1],
                                   :envelop => row[2],
                                   :model_no => row[3],
                                   :quantity => row[5],
                                   :merchandiser => row[7],
                                   :principal => row[8],
                                   :reason => row[9],
                                   :faulter => row[10],
                                   :new_delivery => render_new_date(row[11]),
                                   :deal_method => render_deal_method(row[11], row[12]),
                                   :department => row[12].split("\n").map{|x| x.split(" ")}.join("&"),)

      #  binding.pry
        if abnormal.save

            if abnormal.envelop.present?
              GetEnvelopDetailJob.perform_later(abnormal.id)
            elsif abnormal.model_no.present?
              GetModelNoDetailJob.perform_later(abnormal.id)
            end

            success += 1
        else
            failed += 1
            Rails.logger.info("#{row} ----> #{abnormal.errors.full_messages}")
        end
      end

      end
      import.update_column :status, "总共汇入 #{success} 笔，失败 #{failed} 笔"
      import.csv_yun = params[:csv_file]
      import.save


    flash[:notice] = "总共汇入 #{success} 笔，失败 #{failed} 笔"
    redirect_to abnormals_path
  end







  private
  def abnormal_params
    params.require(:abnormal).permit(:envelop, :principal, :image, :reason, :faulter, :new_delivery, :department, :remarks, :input_time, :client, :model_no, :quantity, :raw_delivery, :merchandiser, :deal_method)
  end

  def find_abnormal
    @abnormal = Abnormal.find(params[:id])
  end

  def render_deal_method(str, department)
    if str.present?
      if str.scan(/入机/).present?
        method = "重入机"
      elsif str.scan(/压/).present?
        method = "重压"
      elsif str.scan(/倒/).present?
        method = "重倒"
      elsif str.scan(/旧/).present?
        method = "废旧膜"
      elsif str.scan(/图/).present?
        method = "重画图"
      elsif str.scan(/喷/).present?
        method = "重喷"
      elsif str.scan(/版/).present?
        method = "改版"
      elsif str.scan(/延/).present?
        method = "延期"
      elsif str.scan(/修/).present?
        method = "修理"
      elsif str.scan(/电/).present?
        method = "重电"
      end
    end

    if department.present?
      if department.scan(/旧/).present?
       method = method << "&" << "废旧模" if method.present?
       method = "废旧模" unless method.present?
     end
   end

   return method
  end

  def render_new_date(str)
    if str.to_s.scan(/\A20../).present?
      str.to_s.scan(/\d*-\d*-\d*/).first
    elsif str.to_s.scan(/\d*-\d*/).first.present?
      "2007-" + str.to_s.scan(/\d*-\d*/).first.to_s
    end
  end
end
