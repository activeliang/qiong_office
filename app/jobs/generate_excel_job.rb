class GenerateExcelJob < ApplicationJob
  queue_as :default

  def perform(start_on, end_on, file_name, root_url)
    # //时间的筛选
    params = { start_on: start_on, end_on: end_on }
    @abnormals = Abnormal.render_filter_data(params)
    @abnormals.each do |r|
      #把图片下载回本地
      if r.image.present?
        if r.envelop.present?
          unless File.exist?("#{Rails.root}/public/images/#{r.envelop}.jpg")
            open("#{Rails.root}/public/images/#{r.envelop}.jpg","wb"){|f|f.write(RestClient.get(r.image.thumb.url + "?imageView2/2/w/130").body)}
          end
        elsif r.model_no.present?
          unless File.exist?("#{Rails.root}/public/images/#{r.model_no}.jpg")
            open("#{Rails.root}/public/images/#{r.model_no}.jpg","wb"){|f|f.write(RestClient.get(r.image.thumb.url + "?imageView2/2/w/130").body)}
          end
        end
      end
    end
    down_url = "#{root_url}/abnormals.xlsx?start_on=#{start_on}&end_on=#{end_on}"
    open("#{Rails.root}/public/office/#{file_name}.xlsx","wb"){|f|f.write(RestClient.get(down_url).body)}
  end
end
