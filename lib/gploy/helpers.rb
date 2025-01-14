module Gploy
  module Helpers  
    LOG_PATH = './log/gploylog.log'
    
    def check_if_dir_log_exists
      unless dirExists?("log")
        Dir.mkdir("log") 
        false
      else
        true
      end
    end
    
    def logger(msg, type)
      puts "--> #{msg}"
      File.open(LOG_PATH, 'a+') do |f|
        f.puts "#{Time.now} => |#{type}| #{msg}"
      end
    end
    
    def run_remote(command)
      @shell.exec!(command)
    end

    def dirExists?(dir)
      File.directory? dir
    end

    def run_local(command)
      Kernel.system command
    end

    def sys_link(name)
      run_remote "ln -s ~/rails_app/#{name}/public ~/public_html/#{name}"
    end
    
    def update_hook_into_server(username, url, name)
      run_local "chmod +x config/post-receive && scp config/post-receive #{username}@#{url}:repos/#{name}.git/hooks/"
    end

    def update_hook(username, url, name)
      run_local "scp config/post-receive #{username}@#{url}:repos/#{name}.git/hooks/"
    end
    
    def useMigrations?
      if File.exists?("db/schema.rb")
        true
      else
        false
      end
    end

    def migrate(name)
      log("Running DB:MIGRATE for #{name} app")
      if useMigrations?
        run_remote "cd rails_app/#{name}/ && rake db:migrate RAILS_ENV=production"
      end
    end

    def restart_server(name)
      run_remote "cd rails_app/#{name}/tmp && touch restart.txt"
    end

    def post_commands(config)
      commands = <<CMD
        #!/bin/sh
        cd ~/rails_app/#{config["config"]["app_name"]}
        env -i git reset --hard 
        env -i git pull #{config["config"]["origin"]} master
        env -i rake db:migrate RAILS_ENV=production
        env -i touch ~/rails_app/#{config["config"]["app_name"]}/tmp/restart.txt 
CMD
         puts commands
    end

    def post_commands_server
      commands = <<CMD
        config:
        url: <user_server>
        user: <userbae>
        password: <password>
        app_name: <app_name>
        origin: <git origin>
CMD
        puts commands
    end
  end
  
  def colorize(text, color_code)
    "#{color_code}#{text}e[0m"
  end

  def red(text)
   colorize(text, "e[31m")
  end
  def green(text)
   colorize(text, "e[32m")
  end
  
end
