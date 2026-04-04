module SourceTextable
  def source_text
    if source.start_with?("ost-remote-2")
      "OSTR2 (#{source.last(4)})"
    elsif source.start_with?("ost-remote")
      "OSTR (#{source.last(4)})"
    elsif source.start_with?("ost-live-entry")
      "Live Entry (#{created_by})"
    elsif source == "raceresult-webhook"
      "RRWEB"
    elsif source.start_with?("raceresult-webhook-")
      "RRWEB (#{source.last(4)})"
    else
      source
    end
  end
end
