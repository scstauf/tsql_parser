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
#   parsing/formatters/set_formatter.rb
# object:
#   TSqlParser::Parsing::Formatters::SetFormatter

module TSqlParser::Parsing::Formatters
  require_relative "base_formatter"

  class SetFormatter < BaseFormatter
    def format(text, tab = Defaults.get_default_tab)
      formatted = []
      lines = text.split("\n")
      wait = false
      set_lines = []
      special_set_keywords = %w[ANSI_DEFAULTS ANSI_NULL_DFLT_OFF ANSI_NULL_DFLT_ON ANSI_NULLS ANSI_PADDING ANSI_WARNINGS ARITHABORT ARITHIGNORE CONCAT_NULL_YIELDS_NULL CURSOR_CLOSE_ON_COMMIT DATEFIRST DATEFORMAT DEADLOCK_PRIORITY FIPS_FLAGGER FMTONLY FORCEPLAN IDENTITY_INSERT IMPLICIT_TRANSACTIONS LANGUAGE LOCK_TIMEOUT NOCOUNT NOEXEC NUMERIC_ROUNDABORT OFFSETS PARSEONLY QUERY_GOVERNOR_COST_LIMIT QUOTED_IDENTIFIER REMOTE_PROC_TRANSACTIONS ROWCOUNT SHOWPLAN_ALL SHOWPLAN_TEXT SHOWPLAN_XML STATISTICS TEXTSIZE TRANSACTION XACT_ABORT]

      lines.each do |line|
        tokens = line.strip.split(" ")
        first = tokens.first
        next if first.nil?
        next_token = tokens[1] if tokens.size > 1

        if %w[FROM WHERE].include? first and wait
          wait = false
          tab_count = self.get_tab_count(line, tab)
          set_text = set_lines.join("\n")
          first = set_text.strip.split(" ").first
          set = set_text.strip[first.size + 1..]
          new_set = self.format_set(set, tab_count, tab)
          if new_set.nil?
            formatted << line
            next
          end
          formatted << "#{tab * tab_count}SET #{new_set}"
          formatted << line
          set_lines = []
          next
        end

        if first == "SET" and not line.strip.start_with? "SET @"
          if not next_token.nil? and not special_set_keywords.include? next_token
            wait = true
            set_lines << line
          else
            formatted << line
            formatted << ""
          end
        elsif first != "SET" and line.include? " SET " and not line.strip.start_with? "--"
          parts = line.strip.split(" SET ")
          tab_count = self.get_tab_count(line, tab)
          formatted << "#{tab * tab_count}#{parts[0]}\n"
          parts[1..].each { |p| formatted << "#{tab * tab_count}SET #{self.format_set(p, tab_count, tab)}" }
        elsif wait
          set_lines << line
        else
          formatted << line
        end
      end
      formatted.join("\n")
    end

    private

    def format_set(s, tab_count = Defaults.get_default_tab_count, tab = Defaults.get_default_tab)
      return s if s.nil?
      parts = []
      builder = ""
      parenthesis = 0
      tokens = s.split("")
      comment = false
      skip_count = 0
      tokens.each_with_index do |c, i|
        if skip_count > 0
          skip_count -= 1
          next
        end

        if comment
          if c == "\n"
            comment = false
            parts << builder unless builder.empty?
            builder = ""
          else
            builder << c
          end
          next
        end

        parenthesis += 1 if c == "("
        parenthesis -= 1 if c == ")"
        next_c = tokens[i + 1] if tokens.size > i + 1
        if c == ","
          if parenthesis > 0
            builder << c
          else
            parts << builder unless builder.empty?
            builder = ""
          end
        elsif c == "\n"
          #parts << builder unless builder.empty?
          #builder = ""
        elsif c == "-"
          if next_c == "-"
            comment = true
            skip_count = 1
            parts << builder unless builder.empty?
            builder = "--"
          else
            builder << c
          end
        else
          builder << c
        end
      end
      parts << builder unless builder.empty?
      parts = parts.map { |p| p.strip }.select { |p| not p.empty? }
      "\n#{parts.map { |p| "#{tab * (tab_count + 1)}#{p.strip.gsub(tab, " ")}" }.join(",\n")}"
    end
  end
end
