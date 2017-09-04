class GenerateExcelJob < ApplicationJob
  queue_as :default

  def perform(start_on, end_on, file_name, root_url)

    # //时间的筛选
    if start_on.present?
      @abnormals = Abnormal.where( "input_time >= ?", Date.parse(start_on).beginning_of_day )
    end
    if end_on.present?
      @abnormals = @abnormals.where( "input_time <= ?", Date.parse(end_on).end_of_day )
    end

    if !start_on.present? && !end_on.present?
      # 默认为筛选最近3个月资料
      @abnormals = Abnormal.where( "input_time >= ?", Time.now.months_ago(2).at_beginning_of_month )
    end
    # 时间筛选结束

    @abnormals.each do |r|

      #把图片下载回本地
      if r.image.present?

        if r.envelop.present?
          unless File.exist?("#{Rails.root}/public/images/#{r.envelop}.jpg")
            open("#{Rails.root}/public/images/#{r.envelop}.jpg","wb"){|f|f.write(open(r.image.thumb.url + "?imageView2/2/w/130"){|f|f.read})}
          end
        elsif r.model_no.present?
          unless File.exist?("#{Rails.root}/public/images/#{r.model_no}.jpg")
            open("#{Rails.root}/public/images/#{r.model_no}.jpg","wb"){|f|f.write(open(r.image.thumb.url + "?imageView2/2/w/130"){|f|f.read})}
          end
        end

      end

    end
    down_url = "#{root_url}/abnormals.xlsx?start_on=#{start_on}&end_on=#{end_on}"
    open("#{Rails.root}/public/office/#{file_name}.xlsx","wb"){|f|f.write(open(down_url){|f|f.read})}
  end
end
