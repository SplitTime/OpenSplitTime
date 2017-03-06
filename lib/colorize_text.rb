class ColorizeText

  # Use with puts, for example, puts ColorizeText.red('Warning!')
  # or puts ColorizeText.bold_cyan('Attention:')
  # or print (These methods do not work with p)

  COLORS ||= {white: "30",
              bold_white: "1;30",
              light_grey: "38",
              bold_light_grey: "1;38",
              grey: "37",
              bold_grey: "1;37",
              yellow: "33",
              bold_yellow: "1;33",
              blue: "34",
              bold_blue: "1;34",
              cyan: "36",
              bold_cyan: "1;36",
              red: "31",
              bold_red: "1;31",
              purple: "35",
              bold_purple: "1;35",
              green: "32",
              bold_green: "1;32",
              tan: "33",
              bold_tan: "1;33"}

  class << self
    COLORS.each_key do |color|
      define_method("#{color}") do |text|
        colorize(text, COLORS[color])
      end
    end

    def colorize(text, color_code)
      "\e[#{color_code}m#{text}\e[0m"
    end
  end
end