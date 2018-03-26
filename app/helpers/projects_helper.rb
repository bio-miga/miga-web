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
end

