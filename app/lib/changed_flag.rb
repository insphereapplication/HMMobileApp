module ChangedFlag
  def self.included(model)
    puts "&"*80
    puts "CHANGED FLAG INCLUDED: #{model}"
    model.extend ClassMethods
  end
  
  module ClassMethods
    def local_changed=(changed)
      @@local_changed=changed
    end
    
    def local_changed?
      @@local_changed ||= false
    end
  end
end
