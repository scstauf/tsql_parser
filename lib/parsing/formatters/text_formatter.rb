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
#   parsing/formatter.rb
# object:
#   TSqlParser::Parsing::Formatter

module TSqlParser::Parsing
  require_relative "strategy/__defaults"
  require_relative "format_factory"

  class TextFormatter
    attr_writer :strategy

    def initialize(strategy, text, tab = Defaults.get_default_tab)
      @strategy = FormatFactory.get(strategy)
      @text = text
      @tab = tab
    end

    def format
      @strategy.format(@text, @tab)
    end
  end
end
