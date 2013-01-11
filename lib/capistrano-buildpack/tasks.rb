require 'digest/sha1'

def _cset(name, *args, &block)
  unless exists?(name)
    set(name, *args, &block)
  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.load do

    _cset(:deploy_to) { "/apps/#{application}" }
    _cset(:buildpack_url) { abort "Please specify the buildpack URL to use, set :buildpack_url, 'http://example.com/buildpack'" }
    _cset(:base_port) { abort "Please specify a base port to use, set :base_port, 6500" }
    _cset(:concurrency) { abort "Please specify a concurrency level to use, set :concurrency, 'web-1'" }

    _cset :foreman_export_path, "/etc/init"
    _cset :foreman_export_type, "upstart"
    _cset :nginx_export_path, "/etc/nginx/conf.d"
    _cset :additional_domains, []

    def read_env(name)
      env = {}
      filename = ".env.#{name}"
      return env unless File.exists?(filename)

      File.open(".env.#{name}") do |f|
        f.each do |line|
          key, val = line.split('=', 2)
          env[key] = val
        end
      end

      set :deploy_env, env
    end

    namespace :buildpack do

      task :setup_env do

        set(:buildpack_hash) { Digest::SHA1.hexdigest(buildpack_url) }
        set(:buildpack_path) { "#{shared_path}/buildpack-#{buildpack_hash}" }

        default_run_options[:pty] = true
        default_run_options[:shell] = '/bin/bash'
      end
      
      task :setup do

        sudo "mkdir -p #{deploy_to}"
        sudo "chown -R #{user} #{deploy_to}"

        run("[[ ! -e #{buildpack_path} ]] && git clone #{buildpack_url} #{buildpack_path}; exit 0")
        run("cd #{buildpack_path} && git fetch origin && git reset --hard origin/master")
        run("mkdir -p #{shared_path}/build_cache")

      end

      task "install_foreman_export_nginx" do
        sudo "gem install foreman-export-nginx --update"
      end

      task "compile" do
        run("cd #{buildpack_path} && RACK_ENV=production bin/compile #{release_path} #{shared_path}/build_cache")

        env_lines = []
        deploy_env.each do |k,v|
          env_lines << "#{k}=#{v}"
        end
        env_contents = env_lines.join("\n") + "\n"

        put(env_contents, "#{release_path}/.env")
      end

      task "foreman_export" do
        _use_ssl = exists?(:use_ssl) ? "USE_SSL=on" : ''
        _ssl_cert_path = exists?(:ssl_cert_path) ? "SSL_CERT_PATH=#{ssl_cert_path}" : ''
        _ssl_key_path = exists?(:ssl_key_path) ? "SSL_KEY_PATH=#{ssl_key_path}" : ''
        _force_ssl = exists?(:force_ssl) ? "FORCE_SSL=#{force_ssl}" : ''

        sudo "foreman export #{foreman_export_type} #{foreman_export_path} -d #{release_path} -l /var/log/#{application} -a #{application} -u #{user} -p #{base_port} -c #{concurrency}"
        sudo "env #{_use_ssl} #{_ssl_cert_path} #{_ssl_key_path} #{_force_ssl} ADDITIONAL_DOMAINS=#{additional_domains.join(',')} BASE_DOMAIN=$CAPISTRANO:HOST$ nginx-foreman export nginx #{nginx_export_path} -d #{release_path} -l /var/log/apps -a #{application} -u #{user} -p #{base_port} -c #{concurrency}"
        sudo "service #{application} restart || service #{application} start"
        sudo "service nginx reload || service nginx start"
      end

    end

    before "deploy", "buildpack:setup_env"
    before "deploy:setup", "buildpack:setup_env"
    before "deploy:setup", "buildpack:setup"
    after  "deploy:setup", "buildpack:install_foreman_export_nginx"
    before "deploy", "buildpack:setup"
    before "deploy:finalize_update", "buildpack:compile"
    after  "deploy:create_symlink", "buildpack:foreman_export"

    task 'remote' do
      buildpack.setup_env
      command=ARGV.values_at(Range.new(ARGV.index('remote')+1,-1))
      run "cd #{current_path}; foreman run #{command*' '}"
      exit(0)      
    end

  end
end
