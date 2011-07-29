load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'lib/capistrano/db_recipes'

load 'config/deploy' # remove this line to skip loading any of the default tasks

namespace :memcached do 
  desc "Start memcached"
  task :start, :roles => [:app] do
    sudo "/etc/init.d/memcached start"
  end

  desc "Stop memcached"
  task :stop, :roles => [:app] do
    sudo "/etc/init.d/memcached stop"
  end

  desc "Restart memcached"
  task :restart, :roles => [:app] do
    sudo "/etc/init.d/memcached restart"
  end        

  desc "Flush memcached - this assumes memcached is on port 11211"
  task :flush, :roles => [:app] do
    sudo "echo 'flush_all' | nc -q 1 localhost 11211"
  end     
end


namespace :deploy do
  task :copy_configuration_files do
    run "cp #{config_files}/* #{release_path}/config/"
    run "cd #{release_path}; chmod 777 public/images public/stylesheets tmp"
    run "ln -nfs #{shared_path}/vendor_bundle #{release_path}/vendor/bundle"
    run "cd #{release_path} && bundle install"

    memcached.flush
  end

  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  
  task :wipe_cache do
    memcached.restart
    restart
  end

  desc "Notify Hoptoad of the deployment"
  task :notify_hoptoad, :except => { :no_release => true } do
    rails_env = fetch(:hoptoad_env, fetch(:rails_env, "production"))
    local_user = ENV['USER'] || ENV['USERNAME']
    notify_command = "bundle exec rake hoptoad:deploy TO=#{rails_env} REVISION=#{current_revision} REPO=#{repository} USER=#{local_user}"
    notify_command << " API_KEY=c7aceee5954aea78f93e7ca4b22439c7"
    puts "Notifying Hoptoad of Deploy of #{server_type} (#{notify_command})"
    run "cd #{release_path} && #{notify_command}"
    puts "Hoptoad Notification Complete."
  end
end

after "deploy", "notify_hoptoad"
after "deploy:update_code", "deploy:copy_configuration_files"
