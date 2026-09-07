# frozen_string_literal: true

require "date"
require "digest"
require "json"
require "pathname"
require "yaml"

unless Enumerable.method_defined?(:filter_map)
  module Enumerable
    def filter_map
      each_with_object([]) do |item, result|
        value = yield(item)
        result << value if value
      end
    end
  end
end

module PteLint
  LEVELS = {"pte-estrutura" => 0, "pte-claro" => 1, "pte-ia" => 2}.freeze
  SEVERITIES = {"off" => 0, "info" => 1, "warning" => 2, "error" => 3}.freeze
  AUTOMATIC_RULES = %w[R001 R004 R005 R006 R012 R014 R017 R018 R021 R029 R031 R037 R038 R039 R040 R041 R042 R045 R046 R048 R050].freeze
  DEFAULT_ACRONYM_ALLOWLIST = %w[ADVERTÊNCIA API ASCII AVISO BCP CFF CI CLI CTRL CUIDADO DEVE DEVERIA ENG HTML IA IMPORTANTE JSON LF LICENSE LOCKOUT LSP MÁX MCP MÍN MVP NÃO NOTA PERIGO PLN PROC PTE README REST RFC ROADMAP SARIF SI TEST URL UTF VS YAML].freeze
  ABBREVIATION_REGISTRY = {
    "temp." => "temperatura",
    "amb." => "ambiente",
    "aprox." => "aproximadamente",
    "qtd." => "quantidade",
    "obs." => "observação",
    "ref." => "referência"
  }.freeze
  NOMINALIZATIONS = {
    "efetuar a verificação" => "verificar",
    "fazer a verificação" => "verificar",
    "proceder com a instalação" => "instalar",
    "realizar o teste" => "testar",
    "fazer a retirada" => "remover",
    "efetuar o registro" => "registrar"
  }.freeze
  NONSTANDARD_MODALITY = ["convém que", "é necessário que", "é preciso que", "deverá", "deverão", "irá", "irão"].freeze
  INVALID_UNITS = %w[inch inches in pé pés feet foot lb lbs pound pounds °F].freeze
  UNIT_SYMBOLS = %w[V A W Hz kPa Pa mm cm m kg g N N·m s min h °C].freeze
  MALFORMED_UNITS = {
    "kgs" => "kg", "kg." => "kg", "KPA" => "kPa", "kpa" => "kPa", "volts" => "V", "volt" => "V",
    "amps" => "A", "amp" => "A", "watts" => "W", "watt" => "W"
  }.freeze

  class RulePack
    attr_reader :rules, :by_id

    def initialize(path)
      data = YAML.safe_load(File.read(path, encoding: "UTF-8"), permitted_classes: [], aliases: false)
      @rules = data.fetch("rules")
      @by_id = @rules.to_h { |rule| [rule.fetch("id"), rule] }
    end

    def automatic
      @rules.select { |rule| rule.dig("lint", "mode") == "automatic" }
    end
  end

  class Vocabulary
    attr_reader :forbidden

    def initialize(path)
      data = YAML.safe_load(File.read(path, encoding: "UTF-8"), permitted_classes: [], aliases: false)
      concepts = data.fetch("concepts")
      preferred_terms = concepts.flat_map { |concept| [concept.fetch("preferred"), *concept.fetch("admitted")] }
      @forbidden = concepts.flat_map do |concept|
        concept.fetch("forbidden").map { |form| form.merge("concept_id" => concept.fetch("id"), "preferred" => concept.fetch("preferred")) }
      end.reject { |form| preferred_terms.include?(form.fetch("term")) }
    end
  end

  class Config
    attr_reader :data

    def initialize(data)
      @data = data || {}
    end

    def self.load(path = nil)
      return new({}) unless path
      raise Errno::ENOENT, path unless File.file?(path)

      content = File.read(path, encoding: "UTF-8")
      data = File.extname(path).downcase == ".json" ? JSON.parse(content) : YAML.safe_load(content, permitted_classes: [], aliases: false)
      new(data || {})
    end

    def level
      data.fetch("level", "pte-claro")
    end

    def locale
      data.fetch("locale", "pt-BR")
    end

    def rule_override(id)
      value = data.fetch("rules", {}).fetch(id, nil)
      value.is_a?(Hash) ? value.fetch("severity", nil) : value
    end

    def enabled?(rule)
      return false if rule_override(rule.fetch("id")) == "off"
      threshold = LEVELS.fetch(level, LEVELS.fetch("pte-claro"))
      LEVELS.fetch(rule.fetch("level"), 1) <= threshold
    end

    def severity(rule)
      rule_override(rule.fetch("id")) || rule.fetch("severity")
    end

    def allowlist
      configured = data.fetch("acronym_allowlist", [])
      (DEFAULT_ACRONYM_ALLOWLIST + configured).uniq
    end

    def allowlist_for(source_id = nil)
      profile_name = data.fetch("source_profiles", {}).fetch(source_id.to_s, nil) if source_id
      profile = profile_name ? data.fetch("profile_definitions", {}).fetch(profile_name, {}) : {}
      configured = Array(profile.fetch("acronym_allowlist", []))
      (allowlist + configured).uniq
    end

    def term_allowlist_for(source_id = nil)
      return [] unless source_id

      profile_name = data.fetch("source_profiles", {}).fetch(source_id.to_s, nil)
      profile = profile_name ? data.fetch("profile_definitions", {}).fetch(profile_name, {}) : {}
      Array(profile.fetch("term_allowlist", []))
    end

    def profile_for(source_id)
      data.fetch("source_profiles", {}).fetch(source_id.to_s, nil)
    end
  end

  class Document
    attr_reader :path, :text, :body, :frontmatter, :body_offset, :context

    def initialize(path, text, context = {})
      @path = path
      @text = text
      @context = context || {}
      @frontmatter = {}
      @body_offset = 0
      @body = parse_frontmatter
    end

    def lines
      @text.lines
    end

    def line_for(offset)
      absolute_offset = offset + @body_offset
      @text[0...absolute_offset].to_s.count("\n") + 1
    end

    def column_for(offset)
      absolute_offset = offset + @body_offset
      last_newline = absolute_offset <= 0 ? nil : @text.rindex("\n", absolute_offset - 1)
      absolute_offset - (last_newline || -1)
    end

    def byte_offset_for(offset)
      @text[0...(offset + @body_offset)].to_s.bytesize
    end

    def frontmatter?
      !@frontmatter.empty? || @text.start_with?("---\n")
    end

    private

    def parse_frontmatter
      return @text unless @text.start_with?("---\n")

      closing = @text.index("\n---", 4)
      return @text unless closing

      raw = @text[4...closing]
      @frontmatter = YAML.safe_load(raw, permitted_classes: [Date], aliases: false) || {}
      @body_offset = closing + 4
      @text[(closing + 4)..] || ""
    rescue Psych::Exception
      @frontmatter = {}
      @text
    end
  end

  class Engine
    attr_reader :rule_pack, :vocabulary, :config

    def initialize(rule_pack:, vocabulary:, config: Config.new({}))
      @rule_pack = rule_pack
      @vocabulary = vocabulary
      @config = config
    end

    def check_file(path)
      check_text(File.read(path, encoding: "UTF-8"), path)
    end

    def check_text(text, path = "<stdin>", context: {})
      document = Document.new(path, text, context)
      diagnostics = []
      rule_pack.automatic.each do |rule|
        next unless config.enabled?(rule)

        method_name = "check_#{rule.fetch("id")}".to_sym
        diagnostics.concat(send(method_name, document, rule)) if respond_to?(method_name, true)
      end
      diagnostics.sort_by { |diagnostic| [diagnostic["file"], diagnostic.dig("range", "start", "line"), diagnostic.dig("range", "start", "column"), diagnostic["rule"]] }
    end

    private

    def check_R001(document, rule)
      diagnostics = []
      source = mask_literals(document.body)
      vocabulary.forbidden.each do |entry|
        regex = /(?<![\p{L}\p{N}])#{Regexp.escape(entry.fetch("term"))}(?![\p{L}\p{N}])/iu
        source.to_enum(:scan, regex).map { Regexp.last_match }.each do |match|
          next if config.term_allowlist_for(document.context["source_id"]).include?(entry.fetch("term"))
          next if allowed_vocabulary_context?(entry, source, match.begin(0))

          diagnostics << diagnostic(document, rule, match.begin(0), "Use '#{entry.fetch("replacement")}' no lugar de '#{entry.fetch("term")}'.", match[0], suggestion: entry.fetch("replacement"))
        end
      end
      diagnostics
    end

    def check_R004(document, rule)
      source = mask_literals(document.body)
      definitions = source.to_enum(:scan, /\b[\p{L}][\p{L}\s-]{2,}\s*\(([A-ZÀ-Ú][A-ZÀ-Ú0-9-]{1,})\)/u).map { Regexp.last_match }
      acronyms = source.to_enum(:scan, /\b[A-ZÀ-Ú]{2,}\b(?!-[A-ZÀ-Ú0-9])/u).map { Regexp.last_match }
      acronyms.filter_map do |match|
        acronym = match[0]
        definition = definitions.find { |candidate| candidate[1] == acronym }
        next if config.allowlist_for(document.context["source_id"]).include?(acronym) || (definition && definition.begin(0) <= match.begin(0))

        diagnostic(document, rule, match.begin(0), "Expanda a sigla '#{acronym}' na primeira ocorrência desta unidade.", acronym)
      end
    end

    def check_R005(document, rule)
      source = mask_literals(document.body)
      ABBREVIATION_REGISTRY.filter_map do |abbreviation, replacement|
        next unless source.match?(/(?<![\p{L}])#{Regexp.escape(abbreviation)}(?![\p{L}])/iu)

        offset = source.index(/(?<![\p{L}])#{Regexp.escape(abbreviation)}(?![\p{L}])/iu)
        diagnostic(document, rule, offset, "A abreviação '#{abbreviation}' não está registrada.", abbreviation, suggestion: replacement)
      end
    end

    def check_R006(document, rule)
      source = mask_literals(document.body)
      NOMINALIZATIONS.filter_map do |phrase, replacement|
        match = source.match(/\b#{Regexp.escape(phrase)}\b/iu)
        next unless match

        diagnostic(document, rule, match.begin(0), "Prefira o verbo direto '#{replacement}'.", match[0], suggestion: replacement)
      end
    end

    def check_R012(document, rule)
      sentences(document.body).filter_map do |sentence|
        words = sentence[:text].scan(/[\p{L}\p{N}]+/u)
        maximum = rule.dig("lint", "parameters", "maximum") || 25
        next unless words.length > maximum

        diagnostic(document, rule, sentence[:offset], "A frase tem #{words.length} palavras; o limite é #{maximum}.", sentence[:text])
      end
    end

    def check_R014(document, rule)
      sentences(document.body).filter_map do |sentence|
        text = sentence[:text].strip
        text_without_step_marker = text.sub(/\A(?:\d+[.)]|[-*])\s+/u, "")
        next if text_without_step_marker.match?(/\A(?:se|caso)\b/iu)
        next if text_without_step_marker.match?(/\A(?:verifique|confirme|determine|avalie|identifique)\s+se\b/iu)
        next unless text.match?(/\A.+\s+(?:se|caso)\s+[^.!?]+[.!?]?\z/iu)
        next if text.match?(/\b(?:de|para|por|ao|sem)\s+se\s+\p{L}/iu)
        next if text.match?(/\b(?:eu|tu|você|ele|ela|nós|vocês|eles|elas|isso|isto|o|a|um|uma)\s+se\s+(?:torna|tornou|tornar|refere|referir|chama|chamar|baseia|basear|trata|tratar|encontra|encontrar|faz|fazer|usa|usar)\b/iu)

        diagnostic(document, rule, sentence[:offset], "Mova a condição de execução para antes da ação.", text)
      end
    end

    def check_R017(document, rule)
      sentences(document.body).filter_map do |sentence|
        markers = sentence[:text].scan(/\b(?:não|nunca|sem)\b/iu)
        next unless markers.length >= 2

        diagnostic(document, rule, sentence[:offset], "Reescreva a dupla negação como uma instrução direta.", sentence[:text])
      end
    end

    def check_R018(document, rule)
      source = mask_literals(document.body)
      NONSTANDARD_MODALITY.filter_map do |phrase|
        match = source.match(/\b#{Regexp.escape(phrase)}\b/iu)
        next unless match

        diagnostic(document, rule, match.begin(0), "Use uma modalidade normativa padronizada; '#{match[0]}' é impreciso.", match[0])
      end
    end

    def check_R021(document, rule)
      diagnostics = []
      offset = 0
      document.body.lines.each do |line|
        if (match = line.match(/^\s*(?:\d+[.)]|[-*])\s+(.+)$/))
          step = match[1].strip
          if step.match?(/\A(?:a|o|as|os|para|depois|em seguida)\b/iu) && !step.match?(/\A(?:se|caso)\b/iu)
            diagnostics << diagnostic(document, rule, offset + line.index(step), "Inicie o passo com uma ação no imperativo.", step)
          end
        end
        offset += line.length
      end
      diagnostics
    end

    def check_R029(document, rule)
      source = mask_literals(document.body)
      regex = /\b(?:procedimento|passo|seção|página)\s+(?:acima|abaixo|anterior|seguinte)\b|\bconforme\s+acima\b/iu
      source.to_enum(:scan, regex).map { Regexp.last_match }.map do |match|
        diagnostic(document, rule, match.begin(0), "Substitua a referência posicional por ID e título estáveis.", match[0])
      end
    end

    def check_R031(document, rule)
      allowed = rule.dig("lint", "parameters", "allowed") || %w[PERIGO ADVERTÊNCIA CUIDADO AVISO]
      document.body.lines.each_with_index.filter_map do |line, index|
        next if document.context["element"].to_s.match?(/\Ah[1-6]\z/i)
        next if line.match?(/^\s*\#{1,6}\s+/u)

        match = line.match(/^\s*(?:>\s*)?([A-ZÀ-Ú]{4,})\s*(?:—|:)/u)
        next unless match && !allowed.include?(match[1])

        offset = document.body.lines.take(index).join.length + match.begin(1)
        diagnostic(document, rule, offset, "Use uma palavra-sinal registrada e confirme a classificação do risco.", match[1])
      end
    end

    def check_R037(document, rule)
      source = mask_literals(document.body)
      INVALID_UNITS.filter_map do |unit|
        regex = /\b\d+(?:[.,]\d+)?\s*#{Regexp.escape(unit)}\b/iu
        match = source.match(regex)
        next unless match

        diagnostic(document, rule, match.begin(0), "A unidade '#{unit}' não pertence ao perfil ativo.", match[0])
      end
    end

    def check_R038(document, rule)
      source = mask_literals(document.body)
      regex = /\b\d+(?:[.,]\d+)? (?:#{UNIT_SYMBOLS.map { |unit| Regexp.escape(unit) }.join("|")})\b/u
      source.to_enum(:scan, regex).map { Regexp.last_match }.map do |match|
        value, unit = match[0].split(" ", 2)
        diagnostic(document, rule, match.begin(0), "Insira espaço inquebrável entre #{value} e #{unit}.", match[0], suggestion: "#{value}\u00A0#{unit}", fix_safety: "safe")
      end
    end

    def check_R039(document, rule)
      source = mask_literals(document.body)
      MALFORMED_UNITS.filter_map do |bad, replacement|
        match = source.match(/\b\d+(?:[.,]\d+)?\s*#{Regexp.escape(bad)}\b/iu)
        next unless match

        diagnostic(document, rule, match.begin(0), "Use o símbolo padronizado '#{replacement}'.", match[0], suggestion: match[0].sub(/#{Regexp.escape(bad)}\b/i, replacement), fix_safety: "safe")
      end
    end

    def check_R040(document, rule)
      source = mask_literals(document.body)
      regex = /\b\d+(?:[.,]\d+)?\s*-\s*\d+(?:[.,]\d+)?(?:\s|\u00A0)+(?:#{UNIT_SYMBOLS.map { |unit| Regexp.escape(unit) }.join("|")})\b/u
      source.to_enum(:scan, regex).map { Regexp.last_match }.map do |match|
        diagnostic(document, rule, match.begin(0), "Declare se os limites da faixa #{match[0]} são inclusivos.", match[0])
      end
    end

    def check_R041(document, rule)
      source = mask_literals(document.body)
      regex = /\b\d{1,2}\/\d{1,2}\/\d{2,4}\b/
      source.to_enum(:scan, regex).map { Regexp.last_match }.map do |match|
        diagnostic(document, rule, match.begin(0), "Escreva a data por extenso ou use RFC 3339 em campo de dados.", match[0])
      end
    end

    def check_R042(document, rule)
      return [] unless config.locale.start_with?("pt-") || config.locale == "pt"

      source = mask_literals(document.body)
      regex = /\b\d+\.\d+\b(?!\.\d)/
      toc_item = document.context["element"].to_s == "li" && source.match?(/\A\s*\d+(?:\.\d+)*\.\s+/u) && source.match?(/\b\d+\.\d+\b/u)
      source.to_enum(:scan, regex).map { Regexp.last_match }.filter_map do |match|
        next if toc_item

        prefix = source[0...match.begin(0)]
        next if prefix.lines.last.to_s.match?(/^\s*#+\s*$/u)
        next if prefix.end_with?("@", "-", "/")
        next if prefix.match?(/(?:seção|seções|item|capítulo|versão)\s*\z/iu)
        next if match.begin(0).positive? && source[match.begin(0) - 1] == "."
        next if match[0].include?(".") && source[[match.begin(0) - 1, 1].max...match.begin(0)] == "."

        diagnostic(document, rule, match.begin(0), "O número '#{match[0]}' não segue o separador decimal de #{config.locale}.", match[0])
      end
    end

    def check_R045(document, rule)
      source = mask_literals(document.body, preserve_links: true)
      regex = /\[\s*(aqui|saiba mais|link)\s*\]\([^)]*\)/iu
      source.to_enum(:scan, regex).map { Regexp.last_match }.map do |match|
        diagnostic(document, rule, match.begin(0), "Descreva o destino deste link.", match[0])
      end
    end

    def check_R046(document, rule)
      return [] unless document.frontmatter?
      return [] if document.frontmatter.key?("id") && !document.frontmatter["id"].to_s.empty?

      [diagnostic(document, rule, -document.body_offset, "A unidade precisa de identificador único e persistente.", document.path)]
    end

    def check_R048(document, rule)
      return [] unless document.frontmatter?
      variant_keys = %w[variants product_variants models]
      has_variants = variant_keys.any? { |key| document.frontmatter.key?(key) }
      return [] unless has_variants && !document.frontmatter.key?("applies_to")

      [diagnostic(document, rule, -document.body_offset, "Declare produto, variante e versão aplicáveis.", document.path)]
    end

    def check_R050(document, rule)
      return [] unless document.frontmatter?
      required = %w[source revision status reviewed_at]
      missing = required.reject { |key| document.frontmatter.key?(key) && !document.frontmatter[key].to_s.empty? }
      allowed = rule.dig("lint", "parameters", "allowed_status") || %w[draft review approved obsolete]
      invalid_status = document.frontmatter["status"] && !allowed.include?(document.frontmatter["status"])
      return [] if missing.empty? && !invalid_status

      detail = missing.empty? ? "O estado de aprovação não é válido." : "Campos ausentes: #{missing.join(", ")}."
      [diagnostic(document, rule, -document.body_offset, "Complete a proveniência ou revise a validade desta unidade. #{detail}", document.path)]
    end

    def sentences(text)
      masked = mask_literals(text)
      masked = masked.gsub(/^(?:[ \t]*\#{1,6}[ \t]+|[ \t]*>[ \t]?).*$/) { |line| line.gsub(/[^\n]/, " ") }
      results = []
      masked.to_enum(:scan, /[^.!?]+[.!?]+|[^.!?]+$/u).map { Regexp.last_match }.each do |match|
        fragment = masked[match.begin(0)...match.end(0)]
        leading = fragment.index(/\S/u)
        next unless leading

        offset = match.begin(0) + leading
        value = text[offset...match.end(0)]
        results << {text: value.strip, offset: offset} unless value.strip.empty?
      end
      results
    end

    def mask_literals(text, preserve_links: false)
      masked = text.gsub(/```.*?```/m) { |block| block.gsub(/[^\n]/, " ") }
      masked = masked.gsub(/`[^`]*`/) { |block| block.gsub(/[^\n]/, " ") } unless preserve_links
      masked
    end

    def allowed_vocabulary_context?(entry, source, offset)
      contexts = Array(entry["allowed_contexts"])
      return false if contexts.empty?

      left = source[0...offset].to_s.rindex(/[.!?\n]/)
      right = source.index(/[.!?\n]/, offset)
      context = source[(left ? left + 1 : 0)...(right || source.length)]
      contexts.any? do |definition|
        Array(definition["patterns"]).any? do |pattern|
          Regexp.new(pattern.to_s, Regexp::IGNORECASE | Regexp::MULTILINE).match?(context)
        end
      rescue RegexpError
        false
      end
    end

    def diagnostic(document, rule, offset, message, evidence, suggestion: nil, confidence: 1.0, fix_safety: nil)
      line = document.line_for(offset)
      column = document.column_for(offset)
      end_offset = offset + [evidence.to_s.length, 1].max
      end_line = document.line_for(end_offset)
      end_column = document.column_for(end_offset)
      absolute_offset = document.byte_offset_for(offset)
      severity = config.severity(rule)
      fingerprint = Digest::SHA256.hexdigest([rule.fetch("id"), document.path, evidence.to_s.downcase.gsub(/\s+/, " ")].join("\0"))[0, 16]
      result = {
        "rule" => rule.fetch("id"),
        "severity" => severity,
        "message" => message,
        "file" => document.path,
        "range" => {"start" => {"line" => line, "column" => column, "offset" => absolute_offset}, "end" => {"line" => end_line, "column" => end_column, "offset" => document.byte_offset_for(end_offset)}},
        "mode" => rule.dig("lint", "mode"),
        "confidence" => confidence,
        "evidence" => evidence.to_s.strip,
        "fingerprint" => fingerprint,
        "documentation" => "https://github.com/forge-z/pte100/blob/main/rules/catalog.md##{rule.fetch("id").downcase}"
      }
      result["suggestion"] = suggestion if suggestion
      result["fix"] = {"safety" => fix_safety, "replacement" => suggestion} if suggestion && fix_safety
      result
    end
  end

  class Runner
    attr_reader :config, :last_checked_files

    def initialize(config_path: nil, level: nil, locale: nil, rules_path: nil, vocabulary_path: nil)
      discovered_config = config_path || %w[.pte-lint.yaml .pte-lint.yml .pte-lint.json].find { |candidate| File.file?(candidate) }
      config = Config.load(discovered_config)
      config.data["level"] = level if level
      config.data["locale"] = locale if locale
      @config = config
      root = File.expand_path("..", __dir__)
      @rule_pack = RulePack.new(rules_path || File.join(root, "rules", "rules.yaml"))
      @vocabulary = Vocabulary.new(vocabulary_path || File.join(root, "vocabulary", "core.yaml"))
    end

    def check(paths, stdin_text: nil, stdin_filename: "<stdin>")
      engine = Engine.new(rule_pack: @rule_pack, vocabulary: @vocabulary, config: @config)
      files = expand_paths(paths)
      if files.empty? && stdin_text
        @last_checked_files = [stdin_filename]
        return engine.check_text(stdin_text, stdin_filename)
      end
      @last_checked_files = files
      files.flat_map { |path| engine.check_file(path) }
    end

    def check_text(text, path = "<stdin>", context: {})
      Engine.new(rule_pack: @rule_pack, vocabulary: @vocabulary, config: @config).check_text(text, path, context: context)
    end

    def summary(diagnostics, files:)
      {"files" => files, "errors" => diagnostics.count { |d| d["severity"] == "error" }, "warnings" => diagnostics.count { |d| d["severity"] == "warning" }, "info" => diagnostics.count { |d| d["severity"] == "info" }, "suppressed" => 0}
    end

    def result(diagnostics, files:)
      {
        "schema_version" => "1.0",
        "tool" => {"name" => "pte-lint", "version" => "0.1.0"},
        "configuration" => {"standard" => "PTE-100@0.1", "level" => @config.level, "locale" => @config.locale, "digest" => Digest::SHA256.hexdigest(@rule_pack.rules.to_s)[0, 16]},
        "summary" => summary(diagnostics, files: files),
        "diagnostics" => diagnostics
      }
    end

    private

    def expand_paths(paths)
      paths.flat_map do |path|
        if File.directory?(path)
          Dir.glob(File.join(path, "**", "*.{md,markdown,txt,adoc}"))
        elsif File.file?(path)
          [path]
        else
          matches = Dir.glob(path)
          raise ArgumentError, "Nenhum arquivo corresponde a '#{path}'." if matches.empty?

          matches
        end
      end.uniq.sort
    end
  end
end
