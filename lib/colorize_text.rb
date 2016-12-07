module ColorizeText

  # Use with puts, for example, puts red('Warning!')
  # or puts bold_cyan('Attention:')
  # (These methods do not work with p)

  COLORS ||= {bold_white: "1;30",
              white: "30",
              light_grey: "38",
              grey: "37",
              bold_grey: "1;37",
              yellow: "1;33",
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

  COLORS.keys.each do |color|
    define_method("#{color}") do |text|
      colorize(text, COLORS[color])
    end
  end

  def colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end
end