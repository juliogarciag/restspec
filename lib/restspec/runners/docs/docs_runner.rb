require 'tilt'
require 'erb'

require_relative './template_context'

module Restspec
  module Docs
    class DocsRunner < Thor::Group
      TEMPLATE_BY_EXTENSION = {
        '.md' => 'docs.md.erb',
        '.html' => 'docs.html.slim'
      }

      argument :file, :default => 'api_docs.md'

      def generate_docs
        require 'restspec'
        require config_file

        File.write(file, read_template(extension))
      end

      private

      def read_template(extension)
        template_file_name = "templates/#{template_name}"
        template_file = Pathname.new(File.dirname(__FILE__)).join(template_file_name)

        Tilt.new(template_file).render(TemplateContext.new)
      end

      def extension
        match = file.match(/\.[\w]+$/)
        raise NoValidExtensionError if match.blank?
        match[0]
      end

      def template_name
        TEMPLATE_BY_EXTENSION.fetch(extension) do
          raise NoValidExtensionError
        end
      end

      def config_file
        Pathname.new(Dir.pwd).join('spec/api/restspec/restspec_config.rb')
      end

      class NoValidExtensionError < StandardError
        ERROR_MESSAGE = "ERROR: The file passed as argument does not include a valid extension"

        def initialize(msg = ERROR_MESSAGE)
          super(msg)
        end
      end
    end
  end
end
