module ApplicationHelper
  def form_input(extra_classes = '')
    content_tag(:div, class: "mb-3 #{extra_classes}") { yield }
  end

  def list_item(action = nil, opt = {})
    opt[:class] ||= ''
    opt[:class] += ' list-group-item'
    fun = :link_to
    if action.nil?
      fun = :content_tag
      action = :div
    else
      opt[:class] += ' list-group-item-action'
    end
    send(fun, action, opt) { yield }
  end

  def display_data(obj, html_safe = false)
    case obj
    when Float
      obj.round(2).to_s
    when Array
      s = obj.map{ |i| display_data(i, html_safe) }.to_sentence
      html_safe ? s.html_safe : s
    when Hash
      content_tag(:table, class: 'table') do
        obj.map do |k,v|
          content_tag(:tr) do
            content_tag(:td) { content_tag(:strong, k.to_s) } +
              content_tag(:td) { display_data(v, html_safe) }
          end
        end.reduce(:+)
      end
    else
      s = obj.to_s
      html_safe ? s.html_safe : s
    end
  end

  def info_msg(title = '', opts = {}, &blk)
    info_msg_id = info_modal(title, opts, &blk)
    content_tag(:sup, 'class' => 'info-msg-button') do
      fa_icon(
        'info-circle', class: 'btn text-info p-0 m-0',
        data: { toggle: 'modal', target: "##{info_msg_id}" }
      )
    end
  end

  def info_modal(title = '', opts = {})
    @info_msg ||= []
    info_msg_id = SecureRandom.uuid
    @info_msg <<
      content_tag(
        :div, class: 'modal fade', id: "info-msg-#{info_msg_id}",
        tabindex: -1, role: 'dialog',
        aria: { labelledby: "info-msg-#{info_msg_id}-h", hidden: true }
      ) do
        content_tag(
          :div, class: "modal-dialog #{opts[:dialog_class]}", role: :document
        ) do
          content_tag(:div, class: "modal-content #{opts[:content_class]}") do
            content_tag(:div, class: 'modal-header') do
              content_tag(
                :h4, title, class: 'modal-title',
                id: "info-msg-#{info_msg_id}-h"
              ) +
              button_tag(
                type: :button, class: 'close',
                data: { dismiss: :modal }, aria: { label: 'Close' }
              ) do
                content_tag(
                  :span, '&times;'.html_safe, aria: { hidden: true }
                )
              end
            end + content_tag(:div, class: 'modal-body') { yield }
          end
        end
      end
    "info-msg-#{info_msg_id}"
  end

  def info_msg_content
    @info_msg ||= []
    o = @info_msg
    @info_msg = []
    o.empty? ? "" : o.inject(:+)
  end

  def accordion(accordion_id, open = true)
    content_tag(:div, class: 'accordion', id: accordion_id) do
      yield(id: accordion_id, n: open ? 0 : 1)
    end
  end

  def accordion_card(accordion, card_id, title)
    cann_id = "#{accordion[:id]}-#{card_id}"
    expanded = accordion[:n].zero?
    accordion[:n] += 1

    content_tag(:div, class: 'card') do
      link_to(
        '#', class: 'btn card-header text-left h3',
        id: "#{cann_id}-h",
        data: { toggle: 'collapse', target: "##{cann_id}" },
        aria: { expanded: expanded, controls: cann_id }
      ) { fa_icon('caret-down', class: 'mr-2') + content_tag(:span, title) } +
      content_tag(
        :div, id: cann_id, class: "collapse #{'show' if expanded}",
        aria: { labelledby: "#{cann_id}-h" },
        data: { parent: "##{accordion[:id]}" }
      ) { content_tag(:div, class: 'card-body') { yield } }
    end
  end

  def full_title(page_title = '')
    page_title + (" | " unless page_title.empty?) + "MiGA Online"
  end

  def plotly(data, layout={})
    id = SecureRandom.uuid
    content_tag(:div, id:id) do
      javascript_tag "$( Plotly.plot('#{id}', [#{data.to_json}], " +
        "#{layout.to_json}) );"
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

  def plot_quality_deprecated(comp, cont, qual)
    cols = ["rgba(92,184,92,1)", "rgba(91,192,222,1)",
      "rgba(240,173,78,1)", "rgba(217,83,79,1)"]
    comp_l = comp > 80.0 ? 0 : comp > 50.0 ? 1 : comp > 20.0 ? 2 : 3
    cont_l = cont <  4.0 ? 0 : cont < 10.0 ? 1 : cont < 16.0 ? 2 : 3
    qual_l = qual > 80.0 ? 0 : qual > 50.0 ? 1 : qual > 20.0 ? 2 : 3
    comp_n = ["very high", "high", "intermediate", "low"][comp_l]
    cont_n = ["very low", "low", "intermediate", "high"][cont_l]
    qual_n = ["excellent", "high", "intermediate", "low"][qual_l]
    trace1 = {
      x: [
        "completeness (#{comp_n})",
        "contamination (#{cont_n})",
        "quality (#{qual_n})"],
      y: [comp, cont, qual],
      marker:{ color: [cols[comp_l], cols[cont_l], cols[qual_l]] },
      type: "bar"
    }
    plotly(trace1)
  end

  def plot_quality(comp, cont, qual)
    css_class = %w[success info warning danger]
    comp = comp.round(2)
    cont = cont.round(2)
    qual = qual.round(2)
    comp_t = [ 80.0,  50.0,  20.0,   0.0]
    cont_t = [  4.0,  10.0,  16.0, 100.0]
    qual_t = [ 80.0,  50.0,  20.0,   0.0]
    comp_l = comp_t.each_with_index.find { |i, _| comp >= i }[1]
    cont_l = cont_t.each_with_index.find { |i, _| cont <= i }[1]
    qual_l = qual_t.each_with_index.find { |i, _| [qual, 0.0].max >= i }[1]
    comp_n = ['very high', 'high', 'intermediate', 'low' ][comp_l]
    cont_n = ['very low',  'low',  'intermediate', 'high'][cont_l]
    qual_n = ['excellent', 'high', 'intermediate', 'low'][qual_l]
    trace = [
      { v: comp, n: comp_n, l: comp_l, k: 'Completeness',  ticks: comp_t },
      { v: cont, n: cont_n, l: cont_l, k: 'Contamination', ticks: cont_t },
      { v: qual, n: qual_n, l: qual_l, k: 'Quality',       ticks: qual_t }
    ]

    content_tag(:div, style: 'margin: 2em 0;') do
      trace.each do |t|
        concat content_tag(:hr, '', class: 'mx-5') if t[:k] == 'Quality'
        concat content_tag(:div, class: 'row', style: 'margin-bottom:10px;'){
          concat content_tag(:strong, t[:k], class: 'col-sm-4 text-right')
          concat(
            content_tag(:div, class: 'col-sm-4 p-0') do
              concat(
                content_tag(
                  :div, class: 'progress mt-1', style: 'margin-bottom:0;'
                ) do
                  t[:ticks].each_with_index do |pos, k| 
                    concat content_tag(
                      :div, ' ', class: "bg-#{css_class[k]}",
                      style: <<~CSS
                        position: absolute; bottom: -0.2em; height: 0.5em;
                        border: 1px solid white;
                        width: #{t[:k] == 'Contamination' ? pos : 100 - pos}%;
                        #{t[:k] == 'Contamination' ? :left : :right }: 0;
                        z-index: #{5 - k};
                      CSS
                    )
                  end
                  concat content_tag(
                    :div, ' ',
                    class: "progress-bar bg-#{css_class[t[:l]]}",
                    role: 'progressbar',
                    aria: { valuenow: t[:v], valuemin: 0, valuemax: 100 },
                    style: "width: #{t[:v]}%;"
                  )
                end
              )
            end
          )
          concat content_tag(
            :div, "#{t[:v]}% (#{t[:n]})",
            class: "col-sm-4 text-#{css_class[t[:l]]}"
          )
        }
      end
    end
  end

  def glyph(name, opts = {})
    fa_icon(name, opts)
  end

  def reload_page_soon
    @reload_page_soon ||= false
    return if @reload_page_soon || params[:noreload]

    @reload_page_soon = params[:reload_attempt]&.to_i || 0
    @reload_page_soon += 1
    noreload = ''
    time = 20_000 + @reload_page_soon * 10_000
    if @reload_page_soon > 50
      # 3h worth of reloads
      flash[:warning] = 'This page is no longer reloading automatically'
      noreload = 'url.searchParams.set(\'noreload\', true);'
      time = 10
    end
    reload_key = (rand * 1e9).to_i.to_s(16)
    <<~JS.html_safe
      <script id="reload_snippet" data-key="#{reload_key}">
        setTimeout(function() {
          if ($('#reload_snippet').data('key') == '#{reload_key}') {
            var url = new URL(location);
            url.searchParams.set('reload_attempt', #{@reload_page_soon});
            #{noreload}
            window.location.replace(url.toString());
          }
        }, #{time});
      </script>
    JS
  end
end
