require 'uuidtools'

module Distributed
  module UseUuid
    
    def self.included(base) # :nodoc:
      base.extend ARClassMethods
    end
    
    class NoBodyAttributeError < StandardError; end
    class AttrsNotSymbols < StandardError; end
  
    module ARClassMethods  

       # Usage examples:
       #
       #   Class Entry < ActiveRecord::Base
       #     # enables use of uuid attr on the Entry class.  Does not enable 
       #     # schema less attributes.
       #     use_uuid 
       #   end
       #
       #   to also enable shema less attributes, use
       #     use_uuid :schema_less_attrs => [:attrname1, :attrname2]
       #
       #  Attribute names must be symbols.  
       #
       def use_uuid(options = {})
         # don't allow multiple calls
         return if self.included_modules.include?(Distributed::UseUuid::InstanceMethods)
         include Distributed::UseUuid::InstanceMethods
         extend Distributed::UseUuid::ModelClassMethods
         # unless specified in arguments there are no schema less attrs created
         options[:schema_less_attrs] = nil if options[:schema_less_attrs] == [] 

         # enable shema_less_attrs to be accessible in instance methods 
         class_inheritable_reader :schema_less_attrs
         write_inheritable_attribute :schema_less_attrs, options[:schema_less_attrs] 
         
         # if schema less attrs specified, there must be a 'body' attribute.
         if options[:schema_less_attrs]
           raise NoBodyAttributeError if !self.new.attributes.include?('body')
         end     
         # 'id' is still created by schemas and migrations but not used for foreign keys or find
         set_primary_key "uuid" 
         serialize :body if options[:schema_less_attrs] # schema less attrs are stored here
         
         if options[:schema_less_attrs]
           # create the getter/setters for each schema less attribute
           code = ""
           options[:schema_less_attrs].each do |k|
             code <<  "def #{k}; self.body[#{k.to_s.inspect}]; end\n"
             code <<  "def #{k}=(value); self.body[#{k.to_s.inspect}] = value; end\n"
           end
           class_eval code
         end
         
       end
     end  # end module ARClassMethods
     
     
     module ModelClassMethods  

       # Makes sure programmers don't perform find using integer primary key - 
       # raises error if they do.  If you need a performance enhancement
       # that requires using integer ids just use find_by_id() 
       def find(*args)
         if args[0].is_a?(Integer)  
           # model classes that include UseUUID must not do find on integer primary key
           raise "Error in UseUUID.find: you may only use a UUID in the argument to find instances of this class"
         else
           super
         end    
       end 
       
     end  # end module ModelClassMethods
   
   
   
    module InstanceMethods
      
      # Sets the 'uuid' attribute upon object creation if a uuid is not already present. 
      # Assigns value to schema less attributes if they are specified in the arguments.  Otherwise
      # works just like Rails new().  Schema less attributes will return a nil value if not specified
      # on object creation.
      def initialize(attrs = {}, &block) 
        # let user specify schema less attrs in the attrs hash just like normal attrs, even though  
        # we haven't initialized them as a key in body yet. 
        # attr keys may be symbols or strings so normalize to strings for comparison
        if attrs
          attrs = attrs.inject({}) {|memo,(k,v)| memo[k.to_s] = v; memo }
        end  
        # to the schema less attrs where we do  the same.
        if schema_less_attrs
          # schema_less_attrs may be symbols or strings, attrs keys are normalized to strings so convert to strings to do comparison
          schema_less_attrs.collect! {|a| a.to_s }        
          # pull out any schema less attrs from attrs and save for later assignment - this prevents
          # erroring because @attributes['body'] hasn't been defined yet
          attrs_to_assign_later = {}
          if attrs.is_a?(Hash) && !attrs.blank?
             attrs.each do |k, v| 
               if schema_less_attrs.include?(k)  
                 attrs.delete(k)
                 attrs_to_assign_later[k] = v 
               end
             end
           end
        end
        
        # need this to support UUIDs, regardless of whether schema less attrs exist
        # must let AR setup attributes before assigning to body.   
        super 
        unless @attributes['uuid']
         @attributes['uuid'] = UUID.timestamp_create.to_s.gsub!(/-/, "")
        end   
        # assign any attrs that should be in body that came in via the initialization
        if schema_less_attrs
          @attributes['body'] = Hash.new  # so other attr can be key value pairs in body  
          # assign each schema less attr as a key/value in body, unless the key already exists as a real column
          unless attrs_to_assign_later.empty?
           attrs_to_assign_later.each do |k, v|
             if @attributes.has_key?(k)
               raise "#{k} is already defined as a database column - skipping assignment to body\n$@"   
             else
               @attributes['body'][k] = v 
             end
           end  
          end
        end   
      end  
   
    end # module InstanceMethods
    
  end
end  

