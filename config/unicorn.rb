working_directory "/opt/atpay"
pid "/opt/atpay/tmp/pids/unicorn.pid"
stderr_path "/opt/atpay/log/unicorn.log"
stdout_path "/opt/atpay/log/unicorn.log"

listen "/opt/atpay/tmp/sockets/unicorn.atpay.sock"
preload_app true
worker_processes 1
timeout 30
