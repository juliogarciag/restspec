require 'httparty'

module Restspec
  module Endpoints
    class Endpoint < Struct.new(:name)
      attr_accessor :method, :path, :namespace, :raw_url_params, :schema_extensions
      attr_reader :last_response, :last_request

      attr_writer :schema_name

      def execute(body: {}, url_params: {}, query_params: {})
        url = URLBuilder.new(full_path, self.url_params.merge(url_params), query_params).full_url
        request = Request.new(method, url, full_headers, body)

        Network.request(request).tap do |response|
          self.last_request = inject_self_into(response, :endpoint)
          self.last_request = inject_self_into(request, :endpoint)
        end
      end

      def execute_once(body: {}, url_params: {}, query_params: {}, before: ->{ })
        @executed_response ||= begin
          before.call
          execute(body: body, url_params: url_params, query_params: query_params)
        end
      end

      def full_name
        [namespace.try(:name), name].compact.join("/")
      end

      def schema_name
        @schema_name || namespace.try(:schema_name)
      end

      def schema
        @schema ||= begin
          found_schema = schema_from_store
          if found_schema.present?
            found_schema.clone.extend_with(schema_extensions || {})
          else
            nil
          end
        end
      end

      def full_path
        if namespace && in_member_or_collection?
          "#{namespace.full_base_path}#{path}"
        else
          path
        end
      end

      def headers
        @headers ||= {}
      end

      def url_params
        @url_params ||= URLBuilder.new(full_path, raw_url_params).url_params
      end

      def add_url_param_block(param, &block)
        raw_url_params[param] = Proc.new(&block)
      end

      def executed_url
        last_request.url
      end

      private

      attr_writer :last_response, :last_request

      def schema_from_store
        Restspec::SchemaStore.get(schema_name)
      end

      def inject_self_into(object, property)
        object.tap { object.send(:"#{property}=", self) }
      end

      def raw_url_params
        @raw_url_params ||= Restspec::Values::SuperHash.new
      end

      def in_member_or_collection?
        namespace.anonymous?
      end

      def full_headers
        config_headers.merge(headers)
      end

      def config_headers
        Restspec.config.try(:request).try(:headers) || {}
      end
    end
  end
end
