require 'erb'
require 'ap'

def process_erb(erb_file, output_file, local_binding)
  template = ERB.new(File.read(erb_file))
  File.open(output_file, 'w') {|f| f.write(template.result(local_binding)) }
end

namespace :build do
  task :gen_rhoconfig do 
    app_db_version = '3.0'
    min_severity = '5'
    max_log_file_size = '1000000'
    sync_server = 'rhosync.insphereis.net/application'
    quick_quote_url = 'quick/quote'
    resource_center_url = 'resource/center'
    process_erb("#{$app_path}/build/rhoconfig.txt.erb", "#{$app_path}/rhoconfig.txt.tmp", binding)
  end
  
  task :gen_build_yml do 
    name = 'Insite'
    version = '2.1.0'
    iphone_config = 'release'
    iphone_sdk = 'iphoneos4.3'
    codesignidentity = "iPhone Developer: Kyle Norton (XX9U4R9CB6)"
    provisionprofile = '57605487-01A2-48E5-93CE-A160E7631951'
    package_name = 'com.insphere.insite' 
    sdk_path = "/Library/ParivedaInsite/rhodes"
    sdk_version = "2.3.0"
    build_type = "release"
    android_password = "5zW8e3ZuS7DWY0TsnCTyyWnpGSDUqUgj"
    android_push_send = "insphereapplication@insphereis.com"
    android_sdk_version = "2.2"
    android_cert_path = "cert/path"
    android_push_sender = "push_sender"
    encrypt_database = '1'
    bundle_identifier = "com.insphere.insite"
    bundle_url_scheme = 'insite'
    extensions = '["json", "another-extension", "fileutils", "mspec", "crypt"]'
    process_erb("#{$app_path}/build/build.yml.erb", "#{$app_path}/build.yml.tmp", binding)
  end
  
  task :prod => [:gen_rhoconfig, :gen_build_yml, 'device:android:production'] do     
  end 
  
end

