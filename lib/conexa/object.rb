# frozen_string_literal: true

module Conexa
  # Base class for all Conexa objects with dynamic attribute access
  #
  # == Attribute Access via method_missing
  #
  # Attributes can be accessed using either snake_case or camelCase:
  #   customer.company_id  # => 3
  #   customer.companyId   # => 3 (converted to snake_case internally)
  #
  # The API returns camelCase attributes which are stored as snake_case.
  # method_missing automatically converts any camelCase calls to snake_case.
  #
  # == Attribute Assignment
  #
  # Attributes can be set using snake_case:
  #   customer.name = "New Name"
  #   customer.save
  #
  class ConexaObject
    attr_reader :attributes

    RESOURCES = Dir[File.expand_path('../resources/*.rb', __FILE__)].map do |path|
      File.basename(path, '.rb').to_sym
    end

    def initialize(response = {})
      @attributes = Hash.new
      @unsaved_attributes = Set.new

      update response
    end

    def []=(key,value)
      @attributes[key] = value
      @unsaved_attributes.add key
    end

    def empty?
      @attributes.empty?
    end

    def ==(other)
      self.class == other.class && id == other.id
    end

    def unsaved_attributes
      Hash[@unsaved_attributes.map do |key|
        [ key, to_hash_value(self[key], :unsaved_attributes) ]
      end]
    end

    def to_hash
      Hash[@attributes.map do |key, value|
        [ key, to_hash_value(value, :to_hash) ]
      end]
    end

    def respond_to_missing?(name, include_private = false)
      name_str = Util.to_snake_case(name.to_s)
      return true if name_str.end_with?('=')

      @attributes.key?(name_str) || @attributes.key?(name_str.to_sym) || super
    end

    protected
    def update(attributes)
      # A successful write may answer with no body, in which case Request#call
      # yields nil. "The server told us nothing" means "there is nothing to
      # merge", not a crash — this used to raise NoMethodError from every
      # Model#save/#destroy against a documented 204.
      return self if attributes.nil?

      removed_attributes = @attributes.keys - attributes.to_hash.keys

      removed_attributes.each do |key|
        @attributes.delete key
      end

      attributes.each do |key, value|
        key = Util.to_snake_case(key.to_s)

        @attributes[key] = ConexaObject.convert(value, Util.singularize(key))
        @unsaved_attributes.delete key
      end
    end

    def to_hash_value(value, type)
      case value
      when ConexaObject
        value.send type
      when Array
        value.map do |v|
          to_hash_value v, type
        end
      else
        value
      end
    end

    def method_missing(name, *args, &block)
      name = Util.to_snake_case(name.to_s)

      unless block_given?
        if name.end_with?('=') && args.size == 1
          attribute_name = name[0...-1]
          return self[attribute_name] = args[0]
        end

        if args.size == 0
          if @attributes.key?(name)
            return @attributes[name]
          elsif @attributes.key?(name.to_sym)
            return @attributes[name.to_sym]
          end
          return nil
        end
      end

      if attributes.respond_to? name
        return attributes.public_send name, *args, &block
      end

      super name, *args, &block
    end

    class << self
      def convert(response, resource_name = nil)
        case response
        when Array
          response.map{ |i| convert i, resource_name }
        when Hash
          resource_class_for(resource_name).new(response)
        else
          response
        end
      end

      protected
      def resource_class_for(resource_name)
        return Conexa::ConexaObject if resource_name.nil?
        resource_name = Util.to_snake_case(resource_name)

        if RESOURCES.include? resource_name.to_sym
          Object.const_get "Conexa::#{capitalize_name resource_name}"
        else
          Conexa::ConexaObject
        end
      end

      def capitalize_name(name)
        name.split('_').collect(&:capitalize).join
      end
    end
  end
end
