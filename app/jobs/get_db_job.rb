class GetDbJob < ApplicationJob
  queue_as :default

  def perform(name, version, user)
    require 'miga/cli'

    # Get current registered version (if any)
    project = Project.find_by(path: name)
    if project && project.miga
      project.miga.metadata[:release] =
        "#{project.miga.metadata[:release]} (currently updating)"
      project.miga.save
    end

    # Download
    error =
      MiGA::Cli.new([
        'get_db', '-n', name, '--db-version', version,
        '--local-dir', Settings.miga_projects, '--no-progress'
      ]).launch
    raise(error) if error.is_a? Exception

    # Register in the database
    project ||= user.projects.create(path: name)
    project.update(reference: true)
    f = File.join(Settings.miga_projects, "#{name}_#{version}.tar.gz")
    File.unlink(f) if File.exist? f
    ActiveRecord::Base.connection.close
  end
end
