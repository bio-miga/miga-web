module ProjectsHelper
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

  def link_to_reference_dataset(project, dataset_name)
    pm = project.miga
    dataset_miga = pm.dataset(dataset_name) unless pm.nil?
    if dataset_miga.nil?
      content_tag(:del, dataset_name, title: 'Reference dataset removed')
    else
      link_to reference_dataset_path(project.id, dataset_name) do
        content_tag(:span, dataset_name.unmiga_name,
              style: 'display:inline;') +
              (dataset_miga.metadata[:is_type] ?
                content_tag(:sup, 'T', title: 'Type strain',
                      style: 'font-weight:bold;') : nil)
      end
    end
  end
end

