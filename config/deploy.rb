# config valid for current version and patch releases of Capistrano
lock "~> 3.19.2"

set :application, "canichess"
set :repo_url, "git@github.com:edpratomo/canichess.git"

set :user, ENV['USER']
set :puma_threads, [4, 16]
set :puma_workers, 0

set :pty, true
set :use_sudo, false

#set :stage, "production"
set :deploy_via, :remote_cache
set :deploy_to, "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind, "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_error_log, "#{release_path}/log/puma.error.log"

set :ssh_options, { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true # Change to false when not using ActiveRecord
set :puma_systemctl_user, :system
set :puma_phased_restart, true

append :linked_files, "config/master.key", ".env"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "public/uploads", "storage"

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

set :nvm_type, :user # or :system, depends on your nvm setup
set :nvm_node, 'v22.11.0'
set :nvm_map_bins, %w{node npm yarn}

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", 'config/master.key'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor", "storage"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
set :keep_releases, 3

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# the following lines are for monit. NOT WORKING
#namespace :deploy do
#  desc 'Restart application'
#  task :restart do
#    on roles(:app), in: :sequence, wait: 5 do
#      # Your restart mechanism here, for example:
#      execute :touch, "/tmp/restart_puma_#{fetch(:application)}_#{fetch(:stage)}.txt"
#    end
#  end

#  after :publishing, :restart
#end

# puma:reload is BROKEN since using systemd unit
# Skip the default puma:reload
Rake::Task["puma:reload"].clear_actions if Rake::Task.task_defined?("puma:reload")

# Use restart instead
after 'deploy:publishing', 'puma:restart'
