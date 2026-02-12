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
      # raise MissingCredentialsError.new("Missing :client_key for extra options #{options}") if options && !options[:client_key]

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

    def respond_to?(name, include_all = false)
      return true if name.to_s.end_with? '='

      @attributes.has_key?(name.to_s) || super
    end

    # def to_s
    #   attributes_str = ''
    #   (attributes.keys - ['id', 'object']).sort.each do |key|
    #     attributes_str += " \033[1;33m#{key}:\033[0m#{self[key].inspect}" unless self[key].nil?
    #   end
    #   "\033[1;31m#<#{self.class.name}:\033[0;32m#{id}#{attributes_str}\033[0m\033[0m\033[1;31m>\033[0;32m"
    # end
    # # alias :inspect :to_s

    protected
    def update(attributes)
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
          return self[name] || self[name.to_sym]
        end
      end

      if attributes.respond_to? name
        return attributes.public_send name, *args, &block
      end

      super name, *args, &block
    end


    class << self
      def convert(response, resource_name = nil, client_key=nil)
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
        # name.gsub(/(\A\w|\_\w)/){ |str| str.gsub('_', '').upcase }
      end
    end
  end
end
