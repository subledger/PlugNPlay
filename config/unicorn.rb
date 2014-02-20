working_directory "/opt/gateway"
pid "/opt/gateway/tmp/pids/unicorn.pid"
stderr_path "/opt/gateway/log/unicorn.log"
stdout_path "/opt/gateway/log/unicorn.log"

listen "/opt/gateway/tmp/sockets/unicorn.gateway.sock"
preload_app true
worker_processes 1
timeout 30
