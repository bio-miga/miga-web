require "miga/tax_dist"

module ProjectsHelper
  def aai_intax(aai, project_id, ds_miga)
    res = MiGA::TaxDist.aai_taxtest(aai, :intax)
    tax = ds_miga.metadata[:tax]
    phrases = []
    res.each do |k,v|
      o = k.to_s.unmiga_name + " belongs to the "
      if tax.nil? or tax[v.first].nil?
        o += "same <b>#{MiGA::Taxonomy.LONG_RANKS[v.first]}</b> of " +
          link_to(ds_miga.name.unmiga_name,
            reference_dataset_path(project_id, ds_miga.name))
      else
        o += "<b>#{MiGA::Taxonomy.LONG_RANKS[v.first]}</b> " +
          "<em>#{tax[v.first].unmiga_name}</em>"
      end
      o += " (p-value: #{v.second.round 2})"
      phrases << o
    end
    if phrases.empty?
      "The dataset doesn't have any close relative in the database "+
        "that can be used to determine its taxonomy."
    else
      "The dataset #{phrases.to_sentence}.".html_safe
    end
  end

  def aai_novel(aai)
    res = MiGA::TaxDist.aai_taxtest(aai, :novel)
    phrases = []
    res.each do |k,v|
      phrases << "" + k.to_s.unmiga_name +
        " belongs to a <b>#{MiGA::Taxonomy.LONG_RANKS[v.first]}</b> not " +
        "represented in the database (p-value: #{v.second.round 2})"
    end
    if phrases.empty?
      "The dataset doesn't have any determinable degree of novelty with " +
        "respect to the database."
    else
      "The dataset #{phrases.to_sentence}.".html_safe
    end
  end
end
