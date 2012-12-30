require 'digest/sha1'

Capistrano::Configuration.instance(true) do
  default_run_options[:pty] = true
  default_run_options[:shell] = '/bin/bash'

  set :deploy_to, "/apps/#{application}"
  set :foreman_export_path, "/etc/init"
  set :foreman_export_type, "upstart"
  set :nginx_export_path, "/etc/nginx/conf.d"

  after "deploy:setup" do
    sudo "chown -R #{user} #{deploy_to}"
    sudo "gem install --upgrade foreman-export-nginx"
  end

  before "deploy" do
    set :buildpack_hash, Digest::SHA1.hexdigest(buildpack_url)
    set :buildpack_path, "#{shared_path}/buildpack-#{buildpack_hash}"

    run("[[ ! -e #{buildpack_path} ]] && git clone #{buildpack_url} #{buildpack_path}; exit 0")
    run("cd #{buildpack_path} && git fetch origin && git reset --hard origin/master")
    run("mkdir -p #{shared_path}/build_cache")
  end
  
  before "deploy:finalize_update" do
    run("cd #{buildpack_path} && RACK_ENV=production bin/compile #{release_path} #{shared_path}/build_cache")

    env_lines = []
    deploy_env.each do |k,v|
      env_lines << "#{k}=#{v}"
    end
    env_contents = env_lines.join("\n") + "\n"

    put(env_contents, "#{release_path}/.env")
  end

  namespace :deploy do
    task :restart do
      sudo "foreman export #{foreman_export_type} #{foreman_export_path} -d #{release_path} -l /var/log/#{application} -a #{application} -u #{user} -p #{base_port} -c #{concurrency}"
      sudo "env ADDITIONAL_DOMAINS=#{additional_domains.join(',')} BASE_DOMAIN=$CAPISTRANO:HOST$ nginx-foreman export nginx #{nginx_export_path} -d #{release_path} -l /var/log/apps -a #{application} -u #{user} -p #{base_port} -c #{concurrency}"
      sudo "service #{application} restart || service #{application} start"
      sudo "service nginx reload || service nginx start"
    end
  end
    
end
