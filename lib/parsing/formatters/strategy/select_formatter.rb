#   __               .__
# _/  |_  ___________|  |           ___________ _______  ______ ___________
# \   __\/  ___/ ____/  |    ______ \____ \__  \\_  __ \/  ___// __ \_  __ \
#  |  |  \___ < <_|  |  |__ /_____/ |  |_> > __ \|  | \/\___ \\  ___/|  | \/
#  |__| /____  >__   |____/         |   __(____  /__|  /____  >\___  >__|
#            \/   |__|              |__|       \/           \/     \/
#
# A very light-weight and opinionated T-SQL parser and formatter.
#
# github.com/scstauf
#
# path:
#   parsing/formatters/select_formatter.rb
# object:
#   TSqlParser::Parsing::Formatters::SelectFormatter

module TSqlParser::Parsing::Formatters
  require_relative "base_formatter"

  class SelectFormatter < BaseFormatter
    def format(text, tab = Defaults.get_default_tab)
      formatted = []
      lines = text.split("\n")
      lines.each do |line|
        first = line.strip.split(" ").first
        next if first.nil?

        if first != "SELECT"
          formatted << line
          next
        end

        tab_count = self.get_tab_count(line, tab)
        select_sql = line.strip[first.size + 1..]
        new_select = self.format_select(select_sql, tab_count, tab)
        if new_select.nil?
          formatted << line
          next
        end
        formatted << line.sub(select_sql, new_select)
      end
      formatted.join("\n")
    end

    private

    def format_select(s, tab_count = Defaults.get_default_tab_count, tab = Defaults.get_default_tab)
      return s if s.nil?

      new_tokens = []
      parenthesis = 0
      builder = ""
      skip_count = 0
      s.split("").each do |c|
        parenthesis += 1 if c == "("
        parenthesis -= 1 if c == ")"

        if skip_count > 0
          skip_count -= 1
          next
        end

        if c == "," and parenthesis == 0
          new_tokens << builder unless builder.empty?
          builder = ""
          skip_count = 1
        else
          builder += c
        end
      end

      new_tokens << builder unless builder.empty?

      "\n#{new_tokens.map { |t| "#{tab * (tab_count + 1)}#{t}" }.join(",\n")}"
    end
  end
end
