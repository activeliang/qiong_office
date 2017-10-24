class AbnormalsController < ApplicationController
  before_action :find_abnormal, only: [:destroy, :edit, :update, :update_envelop]
  before_action :admin_required, only: [:new, :create, :edit, :update, :destroy, :import, :update_envelop]

  def  index
    @abnormals = Abnormal.render_filter_data(params).paginate(:page => params[:page], :per_page => 30)
    @start_date = params[:start_on].present? ?  Date.parse(params[:start_on]).beginning_of_day : Time.now.months_ago(2).at_beginning_of_month
    @end_date = Date.parse(params[:end_on]).end_of_day if params[:end_on].present?
    # 页面备用的链接
    @envelop_link = "http://www.diastarasia.com/Diastar/Envelop.do?action=searchEnvelop&envelopID="
    @model_no_link = "http://www.diastarasia.com/Diastar/ModelNo.do?action=searchModelNo&SearchBy=ByModelNo&modelNo="
    # 生成 按部门，按处理方式 分类的备用哈希
    @department_hash = Abnormal.render_department_hash(@abnormals)
    @deal_method_hash = Abnormal.render_deal_method_hash(@abnormals)
    respond_to do |format|
      format.xlsx{}
      format.html {
        # 生成图表所需要的哈希参数，然后在前端喂给js
        @all_department_chart_pie = render_chart_description(@department_hash, "department", "pie", "各部门异常数据")
        @all_department_chart_bar = render_chart_description(@department_hash, "department", "bar", "各部门异常数据")
        @all_deal_with_chart_pie = render_chart_description(@deal_method_hash, "deal_method", "pie", "各处理方式统计")
        @all_deal_with_chart_bar = render_chart_description(@deal_method_hash, "deal_method", "bar", "各处理方式统计")
        create_word_cloud_data(@start_date, @end_date, @department_hash, @deal_method_hash)
      }
    end
  end

  def new
    @abnormal = Abnormal.new
    @principal_option = option_1 = FormOption.where(:field => "负责人").first && option_1.content.split('&')
    @department_option = option_2 = FormOption.where(:field => "部门").first && option_2.content.split('&')
    @deal_method_option = option_3 = FormOption.where(:field => "处理方式").first && option_3.content.split('&')
  end

  def create
    if Abnormal.create_abnormal(params, abnormal_params)
      redirect_to :abnormals_path, notice: "新增成功！"
    else
      render :new
    end
  end

  def edit
    @principal_option = option_1= FormOption.where(:field => "负责人") && option_1.first.content.split('&')
    @department_option = option_2  = FormOption.where(:field => "部门") && option_2.first.content.split('&')
    @deal_method_option = option_3 = FormOption.where(:field => "处理方式") && option_3.first.content.split('&')
  end

  def update
    if @abnormal.update_abnormal(params)
      redirect_to :abnormals_path, notice: "更新成功!"
    else
      render :new
    end
  end

  # 发起下载
  def download_excel
    time = Time.now.in_time_zone(8).strftime("%m-%d %H:%M")
    GenerateExcelJob.perform_later(params[:start_on], params[:end_on], time, root_url)
    render :json => { :status => "success", :download_url => "#{root_url}office/#{time}.xlsx", :file_url => "#{Rails.root}/public/office/#{time}.xlsx"}
  end

  # 查询文件生成状态
  def excel_file_status
    if File.exist?(params[:file_url])
      render :json => {:status => "ok"}
    else
      render :json => {:status => "failed"}
    end
  end

  # 生成词云图
  def word_cloud
    @word_array = open("#{Rails.root}/public/wordarray/#{params[:file_name]}.txt","r"){|f|f.read}
    render :layout => false
  end

  def destroy
    if @abnormal.destroy
      redirect_to abnormals_path, alert: "已删除！"
    end
  end

  # 手动派出爬虫
  def update_envelop
    if @abnormal.envelop.present?
      GetEnvelopDetailJob.perform_later(@abnormal.id)
    elsif @abnormal.model_no.present?
      GetModelNoDetailJob.perform_later(@abnormal.id)
    end
    redirect_to :back, notice: "已提交更新~！"
  end

  # 导入csv文件
  def import
    redirect_to :back, notice: Import.import_abnormals(params)
  end

  private
  def abnormal_params
    params.require(:abnormal).permit(:envelop, :principal, :image, :reason, :faulter, :new_delivery, :department, :remarks, :input_time, :client, :model_no, :quantity, :raw_delivery, :merchandiser, :deal_method)
  end

  def find_abnormal
    @abnormal = Abnormal.find(params[:id])
  end

  def create_word_cloud_data(start_date, end_date, department_hash, deal_method_hash)
    # 为生成word_cloud准备数据
    @department_hash_file = {}
    @deal_method_hash_file = {}
    @all_reason_file = SecureRandom.hex 6
    GenerateWordArrayJob.perform_later("all", "all", start_date.to_s, (end_date.to_s if end_date.to_s.present?), @all_reason_file)
    department_hash.each do |k, v|
      file_name = SecureRandom.hex 6
      GenerateWordArrayJob.perform_later("department", k, start_date.to_s, (end_date.to_s if end_date.to_s.present?), file_name )
      @department_hash_file[k] =  file_name
    end
    deal_method_hash.each do |k, v|
      file_name = SecureRandom.hex 6
      GenerateWordArrayJob.perform_later("deal_method", k, start_date.to_s, (end_date.to_s if end_date.to_s.present?), file_name )
      @deal_method_hash_file[k] = file_name
    end
  end

  # 返回一个图表所需要的数据。
  def render_chart_description(option_hash, category, style, title)
    bc = []
    fc = []
    color_array = (0..255).to_a
    color_array.shuffle[1..option_hash.count].zip(color_array.shuffle, color_array.shuffle) do |a, b, c|
    bc << "rgba(#{a},#{b},#{c}, 0.2)"
      fc << "rgba(#{a},#{b},#{c}, 1)"
    end
      {
        type: style,
        data: {
            datasets: [{
                data: option_hash.values,
                backgroundColor: bc,
                borderColor: fc,
                borderWidth: 1,
                hoverBorderWidth: 2,
                dataLabels: {
                  colors: fc}
            }],
            labels: option_hash.keys},
        options: {
            responsive: true,
            legend: false,
            title: {
                display: false,
                text: title
            },
            animation: {
                animateScale: true,
                animateRotate: true
            },
            pieceLabel: {
            render: 'label',
            fontColor: '#666',
            position: 'outside'
          }
        }
      }
  end
end
