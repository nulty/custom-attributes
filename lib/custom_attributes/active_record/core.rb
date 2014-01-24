module CustomAttributes
  module ClassMethods
  	def enable_custom_attribute_fields
      has_many :custom_attribute_fields, :class_name=> CustomAttributes::Field, :as => :custom_configurable, :dependent=>:destroy
      include CustomAttributes::ConfigHolderInstanceMethods
    end

    def enable_custom_attributes(options={})
        
    	has_many :custom_attributes, 
        :class_name=> CustomAttributes::Entry, 
        :as => :custom_attributable, 
        :dependent => :destroy

      accepts_nested_attributes_for :custom_attributes
      attr_accessible :custom_attributes_attributes

      class_eval do 
        def self.add_custom_attribute_fields(options)
          define_method :custom_attribute_fields do
            self.send(options[:config_holder]).custom_attribute_fields
          end
        end
      end

      add_custom_attribute_fields(options)
      attr_accessible :custom_attributes_attributes

      include CustomAttributes::AttributeHolderInstanceMethods
    end
  end
  
  module ConfigHolderInstanceMethods
  	def has_custom_attribute_fields?
  		!self.custom_attribute_fields.reload.empty?
  	end
  end
  
  module AttributeHolderInstanceMethods
    def self.included(base)
      def custom_attributes_configured?
        !self.custom_attribute_fields.reload.empty?
      end

      def custom_attributes_populate
        if custom_attributes_configured?
          existing_custom_attribute_fields = custom_attributes.map{| ca | ca.custom_attribute_field_id}
          custom_attribute_fields.each do |field|
            if existing_custom_attribute_fields.include?(field.id)
              custom_attributes[existing_custom_attribute_fields.index(field.id)].explicitly_build_custom_value
            else
              custom_attribute = custom_attributes.build(:custom_attribute_field_id=>field.id)
              custom_attribute.explicitly_build_custom_value
            end

          end 
        end
        
        return custom_attributes
      end
    end
  end
 
  
  def self.included(base)
    base.send :extend, ClassMethods
  end
end

class ActiveRecord::Base
  include CustomAttributes
end