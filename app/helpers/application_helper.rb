module ApplicationHelper
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
	 javascript_tag "Plotly.plot('#{id}', [#{data.to_json}], #{layout.to_json});"
      end
   end
end
