require 'test_helper'

class ProjectsReferenceDatasetsTest < ActionDispatch::IntegrationTest
   def setup
      ENV['MIGA_PROJECTS'] = Rails.root.join("tmp").to_s
      @admin = users(:michael)
      @user = users(:archer)
      @project = @admin.projects.create(path: "foo_bar")
      (1 .. 100).each do |i|
	 name = "vaz_#{i}"
	 MiGA::Dataset.new(@project.miga, name, true, {name:i.to_s})
	 @project.miga.add_dataset(name)
      end
   end
   
   test "should get show with pagination" do
      log_in_as @user
      get project_reference_datasets_path(@project)
      assert_template "projects/reference_datasets"
      assert_select "div.pagination"
      assert_select "ol.datasets li", count: 30
      assert_select "ol.datasets li#dataset-vaz_1 span.name",
	 /#{@project.code}\s+\|\s+vaz 1/
      assert_select "ol.datasets li span.timestamp",
	 /^Updated .* ago\./, count: 30
   end

   test "should get last page" do
      log_in_as @user
      get project_reference_datasets_path(@project), {page: 4}
      assert_template "projects/reference_datasets"
      assert_select "div.pagination"
      assert_select "ol.datasets li", count: 10
   end

   def teardown
      FileUtils.rm_rf @project.miga.path
   end
end
