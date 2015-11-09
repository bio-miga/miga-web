require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
   def setup
      ENV['MIGA_PROJECTS'] = Rails.root.join("tmp").to_s
      @admin = users(:michael)
      @user = users(:archer)
      @project = @admin.projects.create(path: "foo_bar")
      @project_path = @project.miga.path
   end

   test "should be valid" do
      assert @project.valid?
   end

   test "path should be present" do
      @project.path = ""
      assert_not @project.valid?
   end

   test "path should be a miga name" do
      @project.path = "1/2"
      assert_not @project.valid?
      @project.path = " "
      assert_not @project.valid?
   end

   def teardown
      FileUtils.rm_rf @project_path
   end

end
