class Import < ApplicationRecord
  has_many :abnormals, dependent: :destroy
  mount_uploader :csv_yun, CsvYunUploader
end
