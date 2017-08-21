class CheckFormFieldJob < ApplicationJob
  queue_as :default

  def perform(principal, department)
    principal_option = FormOption.where(:field => "负责人").first
    department_option = FormOption.where(:field => "部门").first
    # 判断负责人是否存在，选择性增加
    unless principal_option.present?
      FormOption.create(:field => "负责人", :content => principal)
    else
      unless principal_option.content.split('&').include?(principal)
        principal_option.content = principal_option.content << '' << '&' << principal
        principal_option.save
      end
    end
    # 判断部门是否存在，选择性增加
    unless department_option.present?
      FormOption.create(:field => "部门", :content => department)

    else
      unless department_option.content.split('&').include?(department)
        department_option.content = department_option.content << '' << '&' << department
        department_option.save
      end
    end
  end
end
