class CheckFormFieldJob < ApplicationJob
  queue_as :default

  def perform(principal, departments, deal_methods)

    if principal.present?
      principal_option = FormOption.where(:field => "负责人").first
      # 判断负责人是否存在，选择性增加
      unless principal_option.present?
        FormOption.create(:field => "负责人", :content => principal)
      else
        unless principal_option.content.split('&').include?(principal)
          principal_option.content = principal_option.content << '' << '&' << principal
          principal_option.save
        end
      end
    end

    if departments.present?
      department_option = FormOption.where(:field => "部门").first
      departments.each do |department|
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

    if deal_methods.present?
      deal_method_option = FormOption.where(:field => "处理方式").first
      deal_methods.each do |deal_method|
      # 判断处理方式是否存在，选择性增加
        unless deal_method_option.present?
          FormOption.create(:field => "处理方式", :content => deal_method)
        else
          unless deal_method_option.content.split('&').include?(deal_method)
            deal_method_option.content = deal_method_option.content << '' << '&' << deal_method
            deal_method_option.save
          end
        end
      end
    end
  end

end
