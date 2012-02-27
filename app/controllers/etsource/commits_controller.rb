class Etsource::CommitsController < ApplicationController
  layout 'etsource'
  before_filter :find_commit, :only => [:import, :export]
  before_filter :setup_etsource

  authorize_resource :class => false

  # data/latest/etsource/commits/current
  def show
  end

  def index
    @branch = params[:branch] || @etsource.current_branch || 'master'
    @branch = 'master' if @etsource.detached_branch?
    @branches = @etsource.branches
    @etsource.checkout @branch
    @output = @etsource.refresh if params[:commit] == 'Refresh'
    @commits = @etsource.commits
  end

  # like export, but will update inputs and gqueries
  #
  def import
    sha = params[:id]
    @etsource.checkout sha
    @commit.import! and @etsource.update_latest_import_sha(sha) and @etsource.update_latest_export_sha(sha)
    flash.now[:notice] = "It is now a good idea to refresh the gquery cache on all clients (ETM, Mixer, ...)"
    restart_unicorn
  end

  # This will export a revision into APP_CONFIG[:etsource_working_copy]
  # No changes to the db
  #
  def export
    sha_id = params[:id]
    @etsource.export(sha_id)
    restart_unicorn
    redirect_to etsource_commits_path, :notice => "Checked out rev: #{sha_id}"
  end

  private

  def find_commit
    @commit = Etsource::Commit.new(params[:id])
  end

  def restart_unicorn
    system("kill -s USR2 `cat #{Rails.root}/tmp/pids/unicorn.pid`") rescue nil
  end

  def setup_etsource
    @etsource = Etsource::Base.instance
  end
end
