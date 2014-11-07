module Restspec
  module Endpoints
    class Namespace < Struct.new(:name)
      attr_accessor :schema_name, :base_path

      def add_endpoint(endpoint)
        endpoints << endpoint.tap do |endpoint|
          endpoint.namespace = self
        end
      end

      def set_options(options)
        self.base_path = options[:base_path] if options[:base_path]
      end

      def endpoints
        @endpoints ||= []
      end

      def base_path
        @base_path ||= ''
      end

      def get_endpoint(endpoint_name)
        endpoints.find do |endpoint|
          endpoint.name = endpoint_name
        end
      end
    end

    class << Namespace
      attr_accessor :namespaces

      def get_or_create(name: nil)
        get(name) || create(name)
      end

      def get(name)
        namespaces.find do |ns|
          ns.name == name
        end
      end

      def get_by_full_name(full_name)
        endpoints.find do |endpoint|
          endpoint.full_name == full_name
        end
      end

      def create_by_full_name(full_name)
        get_by_full_name(full_name).dup
      end

      def get_by_schema_name(schema_name)
        namespaces.find do |namespace|
          namespace.schema_name == schema_name
        end
      end

      def create(name)
        new(name).tap do |ns|
          namespaces << ns
        end
      end

      def namespaces
        @namespaces ||= []
      end

      private

      def endpoints
        namespaces.map(&:endpoints).flatten
      end
    end
  end
end
