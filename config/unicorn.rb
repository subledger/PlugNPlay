working_directory "/opt/granular"
pid "/opt/granular/tmp/pids/unicorn.pid"
stderr_path "/opt/granular/log/unicorn.log"
stdout_path "/opt/granular/log/unicorn.log"

listen "/opt/granular/tmp/sockets/unicorn.granular.sock"
preload_app true
worker_processes 1
timeout 30
