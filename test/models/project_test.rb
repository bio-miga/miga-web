require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
   def setup
      ENV['MIGA_PROJECTS'] = Rails.root.join("tmp").to_s
      @admin_user = users(:michael)
      @user = users(:archer)
      @project = @admin_user.projects.create(path: "foo_bar")
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

end
