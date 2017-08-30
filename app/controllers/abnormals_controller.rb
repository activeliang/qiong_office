class AbnormalsController < ApplicationController
  before_action :find_abnormal, only: [:destroy, :edit, :update]

  def  index
    # //时间的筛选
    if params[:start_on].present?
      @abnormals = Abnormal.where( "input_time >= ?", Date.parse(params[:start_on]).beginning_of_day )
      @start_date = Date.parse(params[:start_on]).beginning_of_day
    end
    if params[:end_on].present?
      @abnormals = @abnormals.where( "input_time <= ?", Date.parse(params[:end_on]).end_of_day )
      @end_date = Date.parse(params[:end_on]).end_of_day
    end

    if !params[:start_on].present? && !params[:end_on].present?
      # 默认为筛选最近三个月资料
      @abnormals = Abnormal.where( "input_time >= ?", Time.now.months_ago(2).at_beginning_of_month )
      @start_date = Time.now.months_ago(2).at_beginning_of_month
    end
    # 时间筛选结束

    # 页面备用的链接
    @envelop_link = "http://www.diastarasia.com/Diastar/Envelop.do?action=searchEnvelop&envelopID="
    @model_no_link = "http://www.diastarasia.com/Diastar/ModelNo.do?action=searchModelNo&SearchBy=ByModelNo&modelNo="
    # 生成 按部门，按处理方式 分类的备用哈希
    @department_hash = Hash.new(0)
    @deal_method_hash = Hash.new(0)
    # 生成部门统计和处理方式统计的数据
      @abnormals.each do |abnormal|
        if abnormal.department.present?
          abnormal.department.split("&").each do |d|
            @department_hash[d] += abnormal.quantity
          end
        end
        if abnormal.deal_method.present?
          abnormal.deal_method.split("&").each do |d|
            @deal_method_hash[d] += abnormal.quantity
          end
        end
      end
    # 根据请求格式分开响应
    respond_to do |format|

      format.xlsx{
        @abnormals.each do |r|

          #判断图片是否存在
          if r.image.present?
            get_image_url = r.image.thumb.url
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


      format.html {
        # 生成图表所需要的哈希参数，然后在前端喂给js
        @all_department_chart_pie = render_chart_description(@department_hash, "department", "pie", "各部门异常数据")
        @all_department_chart_bar = render_chart_description(@department_hash, "department", "bar", "各部门异常数据")
        @all_deal_with_chart_pie = render_chart_description(@deal_method_hash, "deal_method", "pie", "各处理方式统计")
        @all_deal_with_chart_bar = render_chart_description(@deal_method_hash, "deal_method", "bar", "各处理方式统计")

        # 为生成word_cloud准备数据
        @department_hash_file = {}
        @deal_method_hash_file = {}
        @all_reason_file = SecureRandom.hex 6

        @department_hash.each do |k, v|
          file_name = SecureRandom.hex 6
          GenerateWordArrayJob.perform_later("department", k, @start_date.to_s, (@end_date.to_s if @end_date.to_s.present?), file_name )
          @department_hash_file[k] =  file_name
        end

        @deal_method_hash.each do |k, v|
          file_name = SecureRandom.hex 6
          GenerateWordArrayJob.perform_later("deal_method", k, @start_date.to_s, (@end_date.to_s if @end_date.to_s.present?), file_name )
          @deal_method_hash_file[k] = file_name
        end

        GenerateWordArrayJob.perform_later("all", "all", @start_date.to_s, (@end_date.to_s if @end_date.to_s.present?), @all_reason_file)
        # binding.pry
      }
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
      render :new
    end
  end

  def edit
    option_1= FormOption.where(:field => "负责人")
    @principal_option = option_1.first.content.split('&') if option_1.present?
    option_2  = FormOption.where(:field => "部门")
    @department_option = option_2.first.content.split('&') if option_2.present?
    option_3 = FormOption.where(:field => "处理方式")
    @deal_method_option = option_3.first.content.split('&') if option_3.present?
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
    data=open("#{abnormals_url(format: "xlsx", start_on: params[:start_on], end_on: params[:end_on])}"){|f|f.read}
    time = Time.now.in_time_zone(8).strftime("%m-%d %H:%M")
    open("#{Rails.root}/public/office/#{time}.xlsx","wb"){|f|f.write(data)}
    render :json => { :status => "success", :download_url => "#{root_url}office/#{time}.xlsx" }
  end

  def word_cloud
    @word_array = open("#{Rails.root}/public/wordarray/#{params[:file_name]}.txt","r"){|f|f.read}
    render :layout => false
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
                                   :quantity => render_quantity(row[5]),
                                   :merchandiser => row[7],
                                   :principal => row[8],
                                   :reason => row[9],
                                   :faulter => (row[10].split("\n").map{|x| x.split(" ")}.join("&") if row[10].present?),
                                   :new_delivery => render_new_date(row[11]),
                                   :deal_method => render_deal_method(row[11], row[12]),
                                   :department => (row[12].gsub(/\?/, '').gsub(/？/, '').gsub(/[a-z]/, '').split("\n").map{|x| x.split(" ")}.join("&") if row[12].present?),)

      #  binding.pry
        if abnormal.save

            if abnormal.envelop.present?
              GetEnvelopDetailJob.set( wait: 1.minutes ).perform_later(abnormal.id)
            elsif abnormal.model_no.present?
              GetModelNoDetailJob.set( wait: 1.minutes ).perform_later(abnormal.id)
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
       method = method << "&" << "废旧膜" if method.present?
       method = "废旧膜" unless method.present?
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

  def render_quantity(str)
    if str.present?
      str
    else
      str = 1
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
