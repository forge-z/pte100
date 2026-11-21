# frozen_string_literal: true

require "json"
require "uri"

# Validador mínimo de JSON Schema 2020-12 para os contratos de saída do
# PTE-Lint. Cobre apenas as palavras-chave usadas em schemas/ e recusa as
# demais, para que uma palavra-chave nova não seja ignorada em silêncio.
class JsonSchemaSubset
  ANNOTATIONS = %w[$schema $id $comment title description].freeze
  SUPPORTED = %w[type const enum required properties additionalProperties items minItems maxItems minimum maximum format $ref $defs].freeze
  TYPES = {
    "object" => ->(value) { value.is_a?(Hash) },
    "array" => ->(value) { value.is_a?(Array) },
    "string" => ->(value) { value.is_a?(String) },
    "integer" => ->(value) { value.is_a?(Integer) },
    "number" => ->(value) { value.is_a?(Numeric) },
    "boolean" => ->(value) { value == true || value == false },
    "null" => ->(value) { value.nil? }
  }.freeze

  def self.load(path)
    new(JSON.parse(File.read(path, encoding: "UTF-8")))
  end

  def initialize(schema)
    @root = schema
  end

  def errors(instance)
    [].tap { |found| validate(@root, instance, "$", found) }
  end

  private

  def validate(schema, value, path, found)
    unknown = schema.keys - ANNOTATIONS - SUPPORTED
    raise ArgumentError, "#{path}: palavra-chave sem suporte no validador: #{unknown.join(", ")}" unless unknown.empty?
    return validate(resolve(schema.fetch("$ref")), value, path, found) if schema.key?("$ref")

    if schema.key?("type")
      types = Array(schema["type"])
      unless types.any? { |type| TYPES.fetch(type).call(value) }
        found << "#{path}: tipo #{value.class} fora de #{types.join("|")}"
        return
      end
    end
    found << "#{path}: valor diferente de #{schema["const"].inspect}" if schema.key?("const") && value != schema["const"]
    found << "#{path}: #{value.inspect} fora de #{schema["enum"].inspect}" if schema.key?("enum") && !schema["enum"].include?(value)
    check_number(schema, value, path, found) if value.is_a?(Numeric)
    check_format(schema, value, path, found) if value.is_a?(String) && schema.key?("format")
    check_object(schema, value, path, found) if value.is_a?(Hash)
    check_array(schema, value, path, found) if value.is_a?(Array)
  end

  def check_number(schema, value, path, found)
    found << "#{path}: #{value} menor que #{schema["minimum"]}" if schema.key?("minimum") && value < schema["minimum"]
    found << "#{path}: #{value} maior que #{schema["maximum"]}" if schema.key?("maximum") && value > schema["maximum"]
  end

  def check_format(schema, value, path, found)
    raise ArgumentError, "#{path}: formato sem suporte: #{schema["format"]}" unless schema["format"] == "uri"

    found << "#{path}: URI inválida: #{value}" unless URI::DEFAULT_PARSER.make_regexp.match?(value) && URI.parse(value).absolute?
  rescue URI::InvalidURIError
    found << "#{path}: URI inválida: #{value}"
  end

  def check_object(schema, value, path, found)
    Array(schema["required"]).each { |key| found << "#{path}: campo obrigatório ausente: #{key}" unless value.key?(key) }
    properties = schema.fetch("properties", {})
    value.each do |key, item|
      if properties.key?(key)
        validate(properties[key], item, "#{path}.#{key}", found)
      elsif schema["additionalProperties"] == false
        found << "#{path}: campo não previsto: #{key}"
      elsif schema["additionalProperties"].is_a?(Hash)
        validate(schema["additionalProperties"], item, "#{path}.#{key}", found)
      end
    end
  end

  def check_array(schema, value, path, found)
    found << "#{path}: menos de #{schema["minItems"]} itens" if schema.key?("minItems") && value.length < schema["minItems"]
    found << "#{path}: mais de #{schema["maxItems"]} itens" if schema.key?("maxItems") && value.length > schema["maxItems"]
    value.each_with_index { |item, index| validate(schema["items"], item, "#{path}[#{index}]", found) } if schema.key?("items")
  end

  def resolve(reference)
    raise ArgumentError, "referência externa sem suporte: #{reference}" unless reference.start_with?("#/")

    reference.delete_prefix("#/").split("/").reduce(@root) { |node, key| node.fetch(key) }
  end
end
