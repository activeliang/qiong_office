class GenerateWordArrayJob < ApplicationJob
  queue_as :default

  def perform(type, field, start_on, *end_on, file_name)
    # 时间筛选
    if start_on.present?
      data = Abnormal.where("input_time >= ?", Date.parse(start_on).beginning_of_day )
    end
    if end_on.first.present?
      data = data.where("input_time <= ?", Date.parse(end_on.first).end_of_day )
    end
    # 生成字段数组
    word_array = []
      data.each do |a|
        if type == "department" && a.department.to_s.include?(field)
          a.quantity.times { word_array << a.reason }
        elsif type == "deal_method" && a.deal_method.to_s.include?(field)
          a.quantity.times { word_array << a.reason }
        elsif type == "all"
          a.quantity.times {word_array << a.reason}
        end
      end

      # 去除一些特殊符号字段
      reason_array = word_array.join("&").gsub(/\s/, "&").gsub(/\d{6}/, "").gsub(/、/, "").gsub(/\-\d/, "").gsub(/\n/, "")
      # 保存文件
      open("#{Rails.root}/public/wordarray/#{file_name}.txt","wb"){|f|f.write(reason_array)}
  end
end
