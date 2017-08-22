class Abnormal < ApplicationRecord
  mount_uploader :image, ImageUploader
  validates_presence_of :envelop, message: "制工袋不能为空！"
  validates_length_of :envelop, message: "输入的制工袋位数有误，请输入6位数制工袋~", minimum: 6
  validate :check_envelop, on: :create

  ENVELOP_RE = /\d{6}/


  private
  def check_envelop
    unless self.envelop =~ ENVELOP_RE
      self.errors.add :envelop, "请输入有效的6位数制工袋号码~"
      return false
    end
  end

end
