module ApplicationHelper
  def info_msg(title="")
    @info_msg ||= []
    info_msg_id = @info_msg.size
    @info_msg << content_tag(:div, "class"=>"modal fade",
          "id"=>"info-msg-#{info_msg_id}","tabindex"=>"-1", "role"=>"dialog",
          "aria-labelledby"=>"info-msg-#{info_msg_id}-h") do
      content_tag(:div, "class"=>"modal-dialog", "role"=>"document") do
        content_tag(:div, "class"=>"modal-content") do
          content_tag(:div, "class"=>"modal-header") do
            button_tag("type"=>"button", "class"=>"close",
                  "data-dismiss"=>"modal", "aria-label"=>"Close") do
              content_tag(:span, "&times;".html_safe, "aria-hidden"=>"true")
            end +
            content_tag(:h4, title, "class"=>"modal-title",
                  "id"=>"info-msg-#{info_msg_id}-h")
          end +
          content_tag(:div, "class"=>"modal-body") do
            yield
          end
        end
      end
    end
    content_tag(:sup, "class"=>"info-msg-button") do
      content_tag(:i, " ","class"=>"glyphicon glyphicon-info-sign text-info",
            "data-toggle"=>"modal","data-target"=>"#info-msg-#{info_msg_id}")
    end
  end

  def info_msg_content
    @info_msg.inject(:+) unless @info_msg.nil?
  end
   
  def full_title(page_title="")
    page_title + (" | " unless page_title.empty?) + "MiGA Clades"
  end
   
  def breadcrumb(location="")
    (location.empty? ? "" : ("/ " + location + "")).html_safe
  end
   
  def plot_distances(file, opts={}, layout={})
    x = []
    y = []
    fh = File.open(file, "r")
    fh.each do |l|
      r = l.split /\s/
      x += [r[0].to_f, r[1].to_f]
      y += [r[2].to_f, r[2].to_f]
    end
    fh.close
    filled_area_plot(x, y, opts, layout)
  end
   
  def filled_area_plot(x, y, opts={}, layout={})
    id = SecureRandom.uuid
    data = opts
    data[:fill] ||= "tozeroy"
    data[:type] ||= "scatter"
    data[:x] = x
    data[:y] = y
    content_tag(:div, id:id) do
      javascript_tag "Plotly.plot('#{id}', [#{data.to_json}], " +
        "#{layout.to_json});"
    end
  end
end
