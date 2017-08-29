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
end
