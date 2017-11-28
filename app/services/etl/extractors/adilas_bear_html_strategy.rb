module ETL::Extractors
  class AdilasBearHTMLStrategy
    include ETL::Errors
    attr_reader :errors

    def initialize(url, options)
      @options = options
      @errors = []
      @html = Nokogiri::HTML(open(url))
    rescue => e
      (errors << bad_url_error(url, e))
    end

    def extract
      OpenStruct.new(row) if errors.empty?
    end

    private

    attr_reader :html, :options

    def row
      {full_name: full_name, bib_number: bib_number, gender: gender, age: age, city: city, state_code: state_code, times: times}
    end

    def full_name
      bib_and_name.split(' - ').last
    end

    def bib_number
      bib_and_name.split(' - ').first.gsub(/\D/, '')
    end

    def bib_and_name
      runner_info.xpath('tr[2]/td[2]').text.squish
    end

    def gender
      bio.split.second
    end

    def age
      bio.split.fourth
    end

    def city
      bio.split(':').last.split(', ').first
    end

    def state_code
      bio.split(':').last.split(', ').last
    end

    def bio
      runner_info.xpath('tr[4]/td[2]').text.squish
    end

    def runner_info
      html.xpath('/html/body/table[2]/tr/td[1]/form/table')
    end

    def times
      html.xpath('/html/body/table[4]/tr')[2..-1].map { |tr| times_from_tr(tr) }.flatten
    end

    def times_from_tr(tr)
      cells = tr.xpath('td').map { |td| td.text.squish }
      [cells[1..2].join(' '), cells[3..4].join(' ')]
    end
  end
end
