
$app_path = File.expand_path(File.dirname(__FILE__))
$config_path = "#{$app_path}/rhoconfig.txt"

namespace :spec do 
  task :iphone do 
    rake = File.readlines($config_path)
    rake.map!{|l| l =~ /^\$target/ ? "start_path = #{args.env}\n"  : l }
    File.open(__FILE__, 'w+') {|f| f.write(rake) }
    
    File.open("#{$app_path}/#{$rhoconfig}", 'w') {|f| f.write() }
  end
end