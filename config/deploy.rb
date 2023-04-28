# config valid for current version and patch releases of Capistrano
lock "~> 3.17.2"

# main vars
set :application, "redmine"
set :repo_url, "git@github.com:alexcode-cc/redmine505.git"
set :deploy_to, "/home/deploy/redmine505"

# deploy-tags vars
# view deployment history: git tag -l -n1
set :deploytag_time_format, "%Y.%m.%d-%H%M%S"
set :deploytag_utc, false
#set :no_deploytags, true
#set :deploytag_commit_message, 'This is my commit message for the deployed tag'

# rvm vars
set :rvm_type, :user                      # Defaults to: :auto
set :rvm_ruby_version, '3.2.2@redmine'  # Defaults to: 'default'
#set :rvm_custom_path, '~/.myrvm'         # only needed if not detected

# Skip assets
Rake::Task['deploy:assets:precompile'].clear_actions
Rake::Task['deploy:assets:backup_manifest'].clear_actions

# Seed data with rvm
namespace :rvm do
  desc "load seed data with rvm"
  task :seed do
    on roles(fetch(:rvm_roles, :all)), wait: 10 do
      rails_env = fetch(:rails_env, 'production')
      rvm_path = fetch(:rvm_path, '~/.rvm')
      rvm_do_prefix = "#{rvm_path}/bin/rvm #{fetch(:rvm_ruby_version)} do"
      execute "cd #{current_path}; #{rvm_do_prefix} rails db:seed RAILS_ENV=#{rails_env}"
    end
  end
end

# Tailing log files
namespace :logs do
  desc "tail rails logs"
  task :tail, :file do |t, args|
    if args[:file]
      on roles(:app) do
        execute "tail -f #{shared_path}/log/#{args[:file]}.log"
      end
    else
      on roles(:app) do
        execute "tail -f #{shared_path}/log/#{fetch(:rails_env)}.log"
      end
    end
  end
end

# upload secret linked files
# /config/configuration.yml
# /config/database.yml
# /config/initializers/secret_token.rb
append :linked_files, 'config/database.yml', 'config/configuration.yml', 'config/initializers/secret_token.rb'
namespace :deploy do
  namespace :check do
    before :linked_files, :set_master_key do
      on roles(:app), in: :sequence, wait: 10 do
        unless test("[ -f #{shared_path}/config/database.yml ]")
          upload! 'config/database.yml', "#{shared_path}/config/database.yml"
        end
        unless test("[ -f #{shared_path}/config/configuration.yml ]")
          upload! 'config/configuration.yml', "#{shared_path}/config/configuration.yml"
        end
        unless test("[ -f #{shared_path}/config/initializers/secret_token.rb ]")
          upload! 'config/initializers/secret_token.rb', "#{shared_path}/config/initializers/secret_token.rb"
        end
      end
    end
  end
end

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

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
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor", "storage"
append :linked_dirs, "plugins", "files", "tmp/pdf", "public/plugin_assets", "log", "tmp/pids", "tmp/cache", "tmp/sockets"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5
set :keep_releases, 2

set :passenger_restart_with_touch, true

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
