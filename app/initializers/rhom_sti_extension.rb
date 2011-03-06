#
# A simple STI framework for Rhom::PropertyBag that supports a single-level inheritance model (i.e., children, but no grandchildren).
# This will use a 'type' attribute in the schema to resolve the class name.'find' will be scoped to the child type and  the 'type'
# attribute will automatically be added when a child class is instantiated.
#
module Rhom
  module PropertyBag   
    module STI
      module ClassMethods
        # Override find to scope for the sti child type
        def find(*args, &block)
          if args[1] && args[1][:conditions]
            if args[1][:conditions].kind_of? Hash
              args[1][:conditions].merge!({:type => self.sti_name})
            elsif args[1][:conditions].kind_of? String
              args[1][:conditions] << "and type='#{self.sti_name}'"
            end
          else
            (args[1] ||= {})[:conditions] = {:type => self.sti_name}
          end
          super(*args, &block)
        end
      
        # override 'name' so that Rho can resolve the source table name to the registered parent (see: RhomObjectFactory.get_source_name)
        def name
          self.superclass.name
        end
      
        # provide a way for child sti classes to access their class name since 'name' is overriden
        def sti_name=(name)
          @sti_name = name
        end
      
        def sti_name
          @sti_name
        end
      end

      module InstanceMethods
        def initialize(*args)
          type = self.class.sti_name
          super(*args)
        end
      end
    end

    module RhomClassMethods
      def inherited(sti_model)
        # someone has inherited from a class that included Rhom::PropertyBag -- this is an STI model
        sti_name = sti_model.name # store name before it's overidden
        sti_model.extend STI::ClassMethods
        sti_model.sti_name = sti_name
        sti_model.send(:include, STI::InstanceMethods)
      end
    end

    def self.included(model)
      model.extend RhomClassMethods
      model.extend PropertyBag
    end
  end
end