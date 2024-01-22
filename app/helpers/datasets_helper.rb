module DatasetsHelper
  def dataset_quality(dataset, words = true)
    md = dataset&.metadata || {}
    qi = md[:quality]&.to_sym
    qk = {
      excellent: [3, 'success'],
      high: [2, 'info'],
      intermediate: [1, 'warning'],
      low: [0, 'danger']
    }[qi]
    in_words = "#{qi.to_s.capitalize} quality #{md[:type]}"
    
    if qi.nil?
      content_tag(:b, 'Missing quality information') if words
    else
      content_tag(:b, class: "text-#{qk[1]} mr-2", title: in_words) do
        3.times.map do |k|
          fa_icon(:star, type: k < qk[0] ? :solid : :regular)
        end.inject(:+)
      end + content_tag(:span, words ? in_words : '')
    end
  end
end
