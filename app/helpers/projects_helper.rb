module ProjectsHelper
  def project_code(project)
    link_to(
      project.code, project,
      class: 'project-code rounded',
      style: "background: #{project.code_color};",
      title: project.path.unmiga_name
    )
  end

  def estimated_wait_time(project_id)
    @estimated_wait_time_last_check ||= []
    @estimated_wait_time ||= []
    if @estimated_wait_time_last_check[project_id].nil? or
          @estimated_wait_time_last_check[project_id] < 48.hours.ago
      p = Project.find(project_id)
      ds = p.query_datasets.where(complete: true).first(5)
      t = 0.0
      ds.each do |d|
        d.miga.each_result do |k,r|
          t += (r.running_time||0) unless k==:mytaxa_scan
        end
      end
      @estimated_wait_time_last_check[project_id] = DateTime.now
      @estimated_wait_time[project_id] = t/ds.size/60
    end
    [ @estimated_wait_time[project_id],
          @estimated_wait_time_last_check[project_id] ]
  end

  def miga_dataset_type(miga_dataset)
    md = miga_dataset&.metadata || {}
    md[:is_type] ?
        content_tag(:sup, md[:seqcode] ? 'Ts' : 'T',
          title: md[:type_rel] || 'Type strain',
          style: 'font-weight:bold;') :
      md[:is_ref_type] ?
        content_tag(:sup, 'R',
          title: md[:type_rel] || 'Reference material',
          style: 'font-weight:bold;') : nil
  end

  def link_to_reference_dataset(project, dataset_name)
    pm = project.miga if project
    ds_miga = pm.dataset(dataset_name) if pm
    if ds_miga.nil?
      content_tag(:del, dataset_name, title: 'Reference dataset removed')
    else
      md = ds_miga.metadata
      link_to(reference_dataset_path(project.id, dataset_name)) do
        content_tag(:span, dataset_name.unmiga_name,
          style: 'display:inline;') +
          md[:strain] ?
            content_tag(:span, ' (') + md[:strain] +
              miga_dataset_type(ds_miga) + content_tag(:span, ')') :
            miga_dataset_type(ds_miga)
      end
    end
  end
end

