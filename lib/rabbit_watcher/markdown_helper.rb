module RabbitWatcher
  module MarkdownHelper
    def self.bold_prefixes(prefixes, texts)
      prefixes.each_with_index.each_with_object([]) do |(prefix, index), lines|
        lines.push "#{bold prefix} #{texts[index]}"
      end.join "\n"
    end

    def self.bold(text)
      "*#{text}*"
    end
  end
end
