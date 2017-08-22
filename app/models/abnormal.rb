class Abnormal < ApplicationRecord
  mount_uploader :image, ImageUploader
  validates_presence_of :envelop, message: "制工袋不能为空！"


end
