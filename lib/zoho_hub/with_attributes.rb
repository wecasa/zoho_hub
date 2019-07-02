# frozen_string_literal: true

module ZohoHub
  # Allows adding attributes to a class, as <tt>attr_accessors</tt> that can then be listed from the
  # class or an instance of that class.
  #
  # === Example
  #
  #   class User
  #     include ZohoHub::WithAttributes
  #
  #     attributes :first_name, :last_name, :email
  #   end
  #
  #   User.attributes # => [:first_name, :last_name, :email]
  #   User.new.attributes # => [:first_name, :last_name, :email]
  #
  #   user = User.new
  #   user.first_name = 'Ricardo'
  #   user.last_name = 'Otero'
  #   user.first_name # => "Ricardo"
  module WithAttributes
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def attributes(*attributes)
        @attributes ||= []

        return @attributes unless attributes

        attr_accessor(*attributes)

        @attributes += attributes
      end

      def attribute_translation(translation = nil)
        @attribute_translation ||= {}

        return @attribute_translation unless translation

        @attribute_translation = translation
      end

      def attr_to_zoho_key(attr_name)
       return attribute_translation[attr_name.to_sym] if attribute_translation.key?(attr_name.to_sym)
       attr_name.to_s.split('_').map(&:capitalize).join('_').to_sym
      end

      def zoho_key_translation
        @attribute_translation.to_a.map(&:rotate).to_h
      end
    end

    # Returns the list of attributes defined for the instance class.
    def attributes
      self.class.attributes
    end

    # This method and the correponding private methods are inspired from Rails ActiveModel
    # github.com/rails/rails/blob/master/activemodel/lib/active_model/attribute_assignment.rb
    def assign_attributes(new_attributes)
      unless new_attributes.is_a?(Hash)
        raise ArgumentError, "When assigning attributes, you must pass a hash as an argument"
      end
      return if new_attributes.empty?

      attributes = Hash[new_attributes.map { |k, v| [k.to_s, v] } ]
      _assign_attributes(attributes.to_h)
    end

    private

    def attr_to_zoho_key(attr_name)
      self.class.attr_to_zoho_key(attr_name)
    end

    def zoho_key_to_attr(zoho_key)
      translations = self.class.zoho_key_translation

      return translations[zoho_key.to_sym] if translations.key?(zoho_key.to_sym)

      zoho_key.to_sym
    end

    def _assign_attributes(attributes)
      attributes.each do |k, v|
        _assign_attribute(k, v)
      end
    end

    def _assign_attribute(k, v)
      setter = :"#{k}="
      if respond_to?(setter)
        public_send(setter, v)
      else
        raise ArgumentError, "Unknown attribute #{k}"
      end
    end
  end
end
