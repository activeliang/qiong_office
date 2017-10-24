class Abnormal < ApplicationRecord
  belongs_to :import,optional: true
  mount_uploader :image, ImageUploader
  # validates_presence_of :envelop, message: "制工袋不能为空！"
  # validates_length_of :envelop, message: "输入的制工袋位数有误，请输入6位数制工袋~", minimum: 6
  # validate :check_envelop, on: :create

  ENVELOP_RE = /\d{6}/

  # 根据时间筛选资料
  def self.render_filter_data(params)
    abnormals = Abnormal.where( "input_time >= ?", Date.parse(params[:start_on]).beginning_of_day ) if params[:start_on].present?
    abnormals = abnormals.where( "input_time <= ?", Date.parse(params[:end_on]).end_of_day ) if params[:end_on].present?
    abnormals = Abnormal.where( "input_time >= ?", Time.now.months_ago(2).at_beginning_of_month ) if !params[:start_on].present? && !params[:end_on].present?
    return abnormals.order(id: "desc")
  end

  # 返回生成部门统计哈希
  def self.render_department_hash(abnormals)
    department_hash = Hash.new(0)
      abnormals.each do |abnormal|
        if abnormal.department.present?
          abnormal.department.split("&").each do |d|
            department_hash[d] += abnormal.quantity
          end
        else
          department_hash["其他"] += abnormal.quantity
        end
      end
    return department_hash
  end

  # 返回生成按处理方式统计哈希
  def self.render_deal_method_hash(abnormals)
    deal_method_hash = Hash.new(0)
      abnormals.each do |abnormal|
        if abnormal.deal_method.present?
          abnormal.deal_method.split("&").each do |d|
            deal_method_hash[d] += abnormal.quantity
          end
        else
          deal_method_hash["其他"] += abnormal.quantity
        end
      end
    return deal_method_hash
  end

  #增加记录
  def self.create_abnormal(params, abnormal_params)
    abnormal = Abnormal.new(abnormal_params)
    abnormal.envelop = params[:abnormal][:envelop].gsub(/\s/, '')
    abnormal.model_no = params[:abnormal][:model_no].gsub(/\s/, '')
    abnormal.department = params[:abnormal][:department].map{|x| x.split(" ").join("&")}.join('&')
    abnormal.faulter = params[:abnormal][:faulter].split(' ').join('&')
    abnormal.deal_method = params[:abnormal][:deal_method].map{|x| x.split(" ").join("&")}.join('&')
    if abnormal.save
      if abnormal.envelop.present?
        GetEnvelopDetailJob.perform_later(abnormal.id)
      elsif @abnormal.model_no.present?
        GetModelNoDetailJob.perform_later(abnormal.id)
      end
      CheckFormFieldJob.perform_later(params[:abnormal][:principal], params[:abnormal][:department], params[:abnormal][:deal_method])
      return true
    else
      return false
    end
  end

  #更新记录
  def update_abnormal(params)
    self.envelop = params[:abnormal][:envelop].gsub(/\s/, '') if params[:abnormal][:envelop].present?
    self.model_no = params[:abnormal][:model_no].gsub(/\s/, '') if params[:abnormal][:model_no].present?
    self.department = params[:abnormal][:department].map{|x| x.split(" ").join("&")}.join('&') if params[:abnormal][:department].join.present?
    self.faulter = params[:abnormal][:faulter].split(' ').join('&') if params[:abnormal][:faultet].present?
    self.deal_method = params[:abnormal][:deal_method].map{|x| x.split(" ").join("&")}.join('&') if params[:abnormal][:deal_method].join.present?
    envelop = self.envelop
    if self.update(abnormal_params)
      if envelop != params[:abnormal][:envelop]
        if self.envelop.present?
          GetEnvelopDetailJob.perform_later(abnormal.id)
        elsif self.model_no.present?
          GetModelNoDetailJob.perform_later(abnormal.id)
        end
      end
      return true
    else
      return false
    end
  end

  private
  def check_envelop
    unless self.envelop =~ ENVELOP_RE
      self.errors.add :envelop, "请输入有效的6位数制工袋号码~"
      return false
    end
  end

end
