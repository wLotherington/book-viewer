require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

before do
  @title = "The Adventures of Sherlock Holmes"
  @contents = File.readlines('data/toc.txt')
end

helpers do
  def in_paragraphs(text)
    text.split("\n\n").map do
      |paragraph| "<p>#{paragraph}</p>"
    end.join
  end

  def highlight_match(text, param)
    text.gsub(param, "<strong>#{param}</strong>")
  end
end

not_found do
  redirect "/"
end

get "/" do
  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]

  redirect "/" unless (1..@contents.size).cover? number

  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read("data/chp#{number}.txt").split("\n\n")
                                               .map.with_index { |chp, idx| "<span id=\"paragraph#{idx}\">#{chp}</span>" }
                                               .join("\n\n")

  erb :chapter
end

def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

def chapters_matching(query)
  results = []

  return results if !query || query.empty?

  each_chapter do |number, name, contents|
    if contents.include?(query)
      results << {number: number, name: name}
      results.last[:paragraphs] = contents.split("\n\n")
                                          .map.with_index { |paragraph, idx| [idx, paragraph] }
                                          .to_h
                                          .select { |par, chp| chp.include?(query) }
    end
  end

  results
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end
