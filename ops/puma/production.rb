threads_count = Integer(ENV.fetch("RAILS_MAX_THREADS", 5))
threads threads_count, threads_count
environment ENV.fetch("RAILS_ENV", "production")
bind "tcp://127.0.0.1:3000"
pidfile "/run/ruby-envelope-vault/puma.pid"
plugin :tmp_restart
