require "test_helper"

class ProjectsControllerTest < ActionController::TestCase
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
    @project.save
  end

  def teardown
    FileUtils.rm_rf $tmp
    ENV["MIGA_HOME"] = nil
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should redirect to login when not logged in" do
    get :new
    assert_redirected_to login_url
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference 'User.count' do
      delete :destroy, id: @project
    end
    assert_redirected_to login_url
  end

  test "should redirect destroy when logged in as a non-admin" do
    log_in_as(@user)
    assert_no_difference 'User.count' do
      delete :destroy, id: @project
    end
    assert_redirected_to root_url
  end

  test "should redirect new" do
    get :new
    assert_redirected_to login_url
    log_in_as(@user)
    get :new
    assert_redirected_to root_url
  end
   
  test "admin should get new" do
    log_in_as(@admin)
    get :new
    assert_template "projects/new"
  end

  test "admin should create and destroy" do
    log_in_as(@admin)
    # Create a project
    assert_difference 'Project.count', 1 do
      post :create, { user_id: @admin, project: { path: "foo_baz" } }
    end
    project = assigns(:project)
    assert_redirected_to project
    # Destroy it
    assert_difference 'Project.count', -1 do
      delete :destroy, id: project
    end
    assert_redirected_to root_url
  end

end
