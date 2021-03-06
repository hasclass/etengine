worker_processes 2
working_directory '/Users/admin/Sites/etengine'

# This loads the application in the master process before forking worker
# processes. Read more about it here:
#
#   http://unicorn.bogomips.org/Unicorn/Configurator.html
#
preload_app true

timeout 30

# This is where we specify the socket. We will point the upstream Nginx module
# to this socket later on
listen '/Users/admin/Sites/etengine/tmp/unicorn.sock', backlog: 64

# File containing the Unicorn process ID.
pid '/Users/admin/Sites/etengine/tmp/unicorn.pid'

# Set the path of the log files inside the log folder of the testapp
stderr_path '/Users/admin/Sites/etengine/log/unicorn.log'
stdout_path '/Users/admin/Sites/etengine/log/unicorn.log'

before_fork do |server, worker|
  # This option works in together with preload_app true setting. What is does
  # is prevent the master process from holding the database connection
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  # When doing a "hot" restart of the Unicorn master, the old master hangs
  # around until it is explicitly killed (so that it can be used if the new
  # master fails to start). Since we got as far as starting a new worker, we
  # end the old process...
  old_pid = '/Users/admin/Sites/etengine/tmp/unicorn.pid.oldbin'

  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill('QUIT', File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # Old master already dead. Just ignore it.
    end
  end
end

after_fork do |server, worker|
  # Here we are establishing the connection after forking worker processes
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
