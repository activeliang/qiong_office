class Abnormal < ApplicationRecord
  before_create :add_default_image
  mount_uploader :image, ImageUploader




  private
  def add_default_image
    self.principal = "贡贡"
    self.image = File.open(File.join("#{Rails.root}/public/images/666.png"))
  end
end
