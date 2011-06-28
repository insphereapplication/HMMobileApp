module ChangedFlag
  def self.included(model)
    model.extend ClassMethods
  end
  
  module ClassMethods
    def local_changed=(changed)
      puts "LOCAL CHANGED CHANGING TO #{changed} FOR #{self.class.name}"
      @local_changed=changed
    end
    
    def local_changed?
      @local_changed.nil? ? @local_changed = true : @local_changed
    end
  end
end
