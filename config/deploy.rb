############################################
# Requirements
############################################
#require 'capistrano/ext/multistage'


############################################
# Setup Stages
############################################
#set :stages, %w(production staging)
#set :default_stage, "staging"

server "localhost", :app

############################################
# Setup Git
############################################
set :application, "mysite"
set :repository, "git@github.com:nontster/mysite.git"
set :scm, :git
set :deploy_to, "/var/www/#{application}"
set :user, "deployer"
set :copy_exclude, [".git", ".DS_Store", ".gitignore", ".gitmodules"]
set :deploy_via, :remote_cache
set :git_enable_submodules, 1
set :default_run_options, {:pty => true}

############################################
# Setup Server
############################################
set :ssh_options, { :forward_agent => true }
set :use_sudo, false
ssh_options[:port] = 2222

############################################
# Recipies
############################################

### WordPress
namespace :wp do
	desc "Create files and directories for WordPress environment"
	task :setup, :roles => :app do
		run "mkdir -p #{shared_path}/uploads"
		
#		set(:secret_keys, capture("curl -s -k https://api.wordpress.org/secret-key/1.1/salt") )
		set(:secret_keys, "")
		set(:wp_siteurl, Capistrano::CLI.ui.ask("Site URL: ") )
		set(:wp_dbname, Capistrano::CLI.ui.ask("Database name: ") )
		set(:wp_dbuser, Capistrano::CLI.ui.ask("Database user: ") )
		set(:wp_dbpass, Capistrano::CLI.password_prompt("Database password: ") )
		set(:wp_dbhost, Capistrano::CLI.ui.ask("Database host: ") )

		db_config = ERB.new <<-EOF 
<?php
	define('DB_NAME', '#{wp_dbname}');
	define('DB_USER', '#{wp_dbuser}');
	define('DB_PASSWORD', '#{wp_dbpass}');
	define('DB_HOST', '#{wp_dbhost}');
	define('DB_CHARSET', 'utf8');
	define('DB_COLLATE', ''); 
	define('WPLANG', '');

	$table_prefix  = 'wp_';
	#{secret_keys}

	define('WP_HOME','#{wp_siteurl}');
	define('WP_SITEURL','#{wp_siteurl}/wordpress');

	//define( 'WP_CONTENT_DIR', $_SERVER['DOCUMENT_ROOT'] . '/content' );
	//define('WP_CONTENT_URL', '#{wp_siteurl}/content');
	define( 'UPLOADS', ''.'uploads' );
?>
    EOF

    	put db_config.result, "#{shared_path}/wp-config-production.php"
	end

	desc "Setup symlinks for a WordPress project"
	task :create_symlinks do
		run "ln -nfs #{shared_path}/uploads #{release_path}/wordpress/uploads"
		run "ln -nfs #{shared_path}/wp-config-production.php #{release_path}/wp-config-production.php"
	end
end

#after "deploy:create_symlink", "wp:create_symlinks"
#after "deploy:setup", "wp:setup"

