require 'sinatra'
require 'sinatra/reloader' if development?

require 'tilt/erubis'

before { @contents = File.readlines('data/toc.txt') }

helpers do
  def in_paragraphs(text)
    text
      .split(/\n{2,}/)
      .map
      .with_index do |par, i|
        "<p class='content-paragraph' id='paragraph-#{i + 1}'>#{par}</p>"
      end
      .join("\n")
  end

  def highlight(term, text)
    text.gsub(/#{term}/i) { |phrase| "<strong>#{phrase}</strong>" }
  end

  def text_line(term, text)
    /(?<=\n|^).*#{term}[^\n$]*/i.match(text).to_s
  end
end

get '/' do
  @page_title = 'Home'

  erb :home # , locals: { page_title: "Page Title" }
end

get '/chapters/:number' do |n|
  pass if n.to_i > @contents.size

  @title = "Chapter #{n}: #{@contents[n.to_i - 1]}"
  @page_title = @title
  @chapter = File.read("data/chp#{n}.txt")

  erb :chapter
end

not_found do
  # "<h3>404 Page Not Found</h3><br><a href='/'>return home</a>"
  redirect '/'
end

def search_for(term)
  res = Hash.new { |h, k| h[k] = [] }
  return res unless term.size > 0

  (1..@contents.size).each_with_object(res) do |chp, results|
    to_search =
      [@contents[chp - 1]] + File.read("data/chp#{chp}.txt").split(/\n{2,}/)
    to_search.each_with_index do |par, par_num|
      next unless /#{term}/i =~ par

      line = text_line(term, par)

      # results[chp] << [par_num, highlight(regex_term, line)]
      results[chp] << [par_num, line]
    end
  end
end

get '/search' do
  @term = params[:query]
  if @term
    @regex_term = @term.split.join('\s+')
    @results = search_for(@regex_term)
  end

  erb :search
end
