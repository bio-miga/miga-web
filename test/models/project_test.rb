require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  def setup
    # Setup MiGA
    $tmp = Dir.mktmpdir
    ENV["MIGA_HOME"] = $tmp
    FileUtils.touch("#{ENV["MIGA_HOME"]}/.miga_rc")
    FileUtils.touch("#{ENV["MIGA_HOME"]}/.miga_daemon.json")
    # Setup Web
    ENV["MIGA_PROJECTS"] = $tmp
    @admin = users(:michael)
    @user = users(:archer)
    @project = @admin.projects.create(path: "foo_bar")
    @project_path = @project.miga.path
  end

  def teardown
    FileUtils.rm_rf $tmp
    ENV["MIGA_HOME"] = nil
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
