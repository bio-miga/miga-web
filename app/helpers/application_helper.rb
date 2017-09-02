module ApplicationHelper
  def info_msg(title="", &blk)
    info_msg_id = info_modal(title, &blk)
    content_tag(:sup, "class"=>"info-msg-button") do
      content_tag(:i, " ","class"=>"glyphicon glyphicon-info-sign text-info",
            "data-toggle"=>"modal","data-target"=>"##{info_msg_id}")
    end
  end

  def info_modal(title="")
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
    "info-msg-#{info_msg_id}"
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

  def plotly(data, layout={})
    id = SecureRandom.uuid
    content_tag(:div, id:id) do
      javascript_tag "Plotly.plot('#{id}', [#{data.to_json}], " +
        "#{layout.to_json});"
    end
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
    data = opts
    data[:fill] ||= "tozeroy"
    data[:type] ||= "scatter"
    data[:x] = x
    data[:y] = y
    plotly(data, layout)
  end

  def plot_assembly(n50, len)
    # Trace1: RefSeq genomes
    trace1 = {
      x: [298471,2240716,3402093,4653910,13033779],
      type: "box",
      hoverinfo: "none",
      name: "RefSeq"
    }
    # Layout
    layout = {
      showlegend: false,
      xaxis: {
        autorange: true,
        zeroline: false,
        title: "Length (bp)"
      },
      annotations: []
    }
    layout[:annotations] << {
      x: len, y: 0.25, text: "Total length",
      showarrow: true, yanchor: "bottom",
      ax: 0, ay: -40
    }
    layout[:annotations] << {
      x: n50, y: 0.25, text: "N50",
      showarrow: true, yanchor: "bottom",
      ax: 0, ay: -20
    } unless n50==len
    plotly(trace1, layout)
  end
end
