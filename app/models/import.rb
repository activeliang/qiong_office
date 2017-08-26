class Import < ApplicationRecord
  has_many :abnormals
  mount_uploader :csv_yun, CsvYunUploader
end
