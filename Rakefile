require 'yaml'

unless File.exists? "build.yml"
  puts "Cannot find build.yml"
  exit 1
end

$app_path = File.expand_path(File.dirname(__FILE__))
$app_config = YAML::load_file("#{$app_path}/build.yml")

if ENV["RHO_HOME"].nil?
  rakefilepath = "#{$app_config["sdk"]}/Rakefile"
else
  rakefilepath = "#{ENV["RHO_HOME"]}/Rakefile"
end

unless File.exists? rakefilepath
  puts "\nCannot find your Rhodes gem or source path: #{rakefilepath}"
  puts "\nIf you have the sdk on your path or have installed the gem this"
  puts "can be resolved by running 'set-rhodes-sdk'"
  puts "\nYou can also set this manually by modifying your build.yml or"
  puts "setting the environment variable RHO_HOME"
  exit 1
end

load rakefilepath

# Dir[File.join(File.dirname(__FILE__),'tasks','**','*.rb')].each { |file| load file }

ios_version = "4.3"

namespace :deploy do 
  task :persist_build_yml do 
    File.open("#{$app_path}/build.yml", 'w') {|f| f.write($app_config.to_yaml) }
  end
  
  task :sim do
    $app_config["iphone"]["sdk"] = "iphonesimulator#{ios_version}"
    Rake::Task['deploy:persist_build_yml'].invoke
  end
  
  task :device do 
    $app_config["iphone"]["sdk"] = "iphoneos#{ios_version}"
    Rake::Task['deploy:persist_build_yml'].invoke
  end
end

