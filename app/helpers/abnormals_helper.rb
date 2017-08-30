module AbnormalsHelper
  def render_content_display(content, style, *group_style)
    color = ["info", "warning", "danger", "primary", "default"]
    if content.present?
      result = []
      if content.include?("&")
        unless group_style.present?
          content.split("&").zip(color.shuffle) do |a, c|
            result << content_tag(:div, content_tag(:p, a, class: "label label-#{c}"), style: "margin: 0px;")
          end
          return result.join("<br>").html_safe
        else
          content.split("&").map!{|a| content_tag(:div, content_tag(:p, a, class: "label label-#{style}"))}.join("<br>").html_safe
        end
      else
        content_tag(:p, content, class: "label label-#{style}")
      end

    end
  end

  def render_last_three_month_start(date)
    date.months_ago(2).strftime("%Y-%m-1")
  end

  def render_last_three_month_end(date)
      date
  end

  def render_rand_color_btn(name,url, id, style)
    color = "#{rand(255)},#{rand(255)},#{rand(255)}"
      link_to name, url, id: id, class: "btn #{style} analyze-btn", style: "margin: 1px; background: rgba(#{color}, 0.3); color: #666; border-color:rgba(#{color},1);"
  end

  def render_date_helper(start_on, end_on)
    start_m = start_on.present? ? start_on.strftime("%Y-%m-%d") : "#{Date.today.month - 2}月1日"
    end_m = end_on.present? ? end_on.strftime("%Y-%m-%d") : "今天"
    return "#{start_m} ~ #{end_m}"
  end

  def render_month_first(m)
    Date.parse("#{Date.today.year}-#{m}-1").beginning_of_day
  end

  def render_month_last(m)
    Date.parse("#{Date.today.year}-#{m + 1}-1").yesterday.end_of_day
  end
end
