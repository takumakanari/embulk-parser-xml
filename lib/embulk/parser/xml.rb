require "rexml/document"

module Embulk
  module Parser

    class XmlParserPlugin < ParserPlugin
      Plugin.register_parser("xml", self)

      def self.transaction(config, &control)
        task = {
          :schema => config.param("schema", :array),
          :root => config.param("root", :string)
        }
        columns = task[:schema].each_with_index.map do |c, i|
          Column.new(i, c["name"], c["type"].to_sym)
        end
        yield(task, columns)
      end

      def run(file_input)
        schema = @task["schema"]
        root = @task["root"]
        while file = file_input.next_file
          REXML::Document.new(file.read).elements.each(root) do |e|
            dest = {}
            e.elements.each do |d|
              dest[d.name] = d.text
            end
            @page_builder.add(make_record(schema, dest))
          end
        end
        @page_builder.finish
      end

      private

      def make_record(schema, e)
        schema.map do |c|
          name = c["name"]
          val = e[name]

          v = val.nil? ? "" : val
          type = c["type"]
          case type
            when "string"
              v
            when "long"
              v.to_i
            when "double"
              v.to_f
            when "boolean"
              ["yes", "true", "1"].include?(v.downcase)
            when "timestamp"
              v.empty? ? nil : Time.strptime(v, c["format"])
            else
              raise "Unsupported type #{type}"
          end
        end
      end
    end

  end
end
