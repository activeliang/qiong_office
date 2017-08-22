class Abnormal < ApplicationRecord
  mount_uploader :image, ImageUploader
  validates_presence_of :envelop, message: "制工袋不能为空！"
  validates_length_of :envelop, message: "输入的制工袋位数有误，请输入6位数制工袋~", minimum: 6


end
