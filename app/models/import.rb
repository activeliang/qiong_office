class Import < ApplicationRecord
  has_many :abnormals, dependent: :destroy
  mount_uploader :csv_yun, CsvYunUploader

  def self.import_abnormals(params)
    csv_string = params[:csv_file].read.force_encoding('utf-8')
    success = 0
    failed = 0
    require 'csv'
    import = self.new
      CSV.parse(csv_string)[1 .. -1].each do |row|
        if row[9].present?     #根据表中的异常原因判断数据有效性
          abnormal = import.abnormals.new( :input_time => row[0].to_s.sub(/日/, '').to_s.gsub(/(年|月)/, '-'),
                                   :client => row[1],
                                   :envelop => row[2],
                                   :model_no => row[3],
                                   :quantity => row[5] ||= 1,
                                   :merchandiser => row[7],
                                   :principal => row[8],
                                   :reason => row[9],
                                   :faulter => (row[10].split("\n").map{|x| x.split(" ")}.join("&") if row[10].present?),
                                   :new_delivery => render_new_date(row[11]),
                                   :deal_method => render_deal_method(row[11], row[12]),
                                   :department => (row[12].gsub(/\?/, '').gsub(/？/, '').gsub(/[a-z]/, '').split("\n").map{|x| x.split(" ")}.join("&") if row[12].present?),)
        if abnormal.save
            if abnormal.envelop.present?
              GetEnvelopDetailJob.set( wait: 1.minutes ).perform_later(abnormal.id)
            elsif abnormal.model_no.present?
              GetModelNoDetailJob.set( wait: 1.minutes ).perform_later(abnormal.id)
            end
            CheckFormFieldJob.set( wait: 1.minutes ).perform_later(row[8], abnormal.department.to_s.split("&"), abnormal.deal_method.to_s.split("&"))
            success += 1
        else
            failed += 1
            Rails.logger.info("#{row} ----> #{abnormal.errors.full_messages}")
        end
      end
      end
      import.update_column :status, "总共汇入 #{success} 笔，失败 #{failed} 笔"
      import.csv_yun = params[:csv_file]
      import.remarks = params[:remarks]
      import.save
    return "总共汇入 #{success} 笔，失败 #{failed} 笔"
  end

  private
  def self.render_deal_method(str, department)
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
    if department.present? && department.scan(/旧/).present?
       method = method << "&" << "废旧膜" if method.present?
       method = "废旧膜" unless method.present?
    end
   return method
  end

  def self.render_new_date(str)
    if str.to_s.scan(/\A20../).present?
      str.to_s.scan(/\d*-\d*-\d*/).first
    elsif str.to_s.scan(/\d*-\d*/).first.present?
      "2007-" + str.to_s.scan(/\d*-\d*/).first.to_s
    end
  end

end
