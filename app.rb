require 'rubygems'
require 'sinatra'
require 'json'
require "net/http"
require "uri"
require "haml"
require "pathname"
require "cgi"

# You can edit these
class Settings
  def basePath
    '/Users/simon/Media/TV Shows'
  end
  
  def sickBeard
    'http://192.168.0.100:8081'
  end
end

# Don't edit below here

class SickBeard
  def addShows
    '/home/addShows'
  end
  
  def searchTVDB
    "#{self.addShows}/searchTVDBForShowName?name="
  end
  
  def addSingleShow
    "#{self.addShows}/addSingleShow"
  end
end

# Original method from http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/classes/Net/HTTP.html
def fetch(uri, postData = {}, limit = 10)
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0
  
  uri = URI.parse(uri)
  
  if postData.empty? then 
    response = Net::HTTP.get_response(uri)
  else 
    response = Net::HTTP.post_form(uri, postData)
  end
  case response
    when Net::HTTPSuccess     then response
    when Net::HTTPRedirection then fetch(response['location'], {}, limit - 1)
    else
      response.error!
  end
end

get '/' do
  haml :index
end

post '/search' do
  settings = Settings.new
  sickbeard = SickBeard.new
  
  show = CGI::escape(params[:query])
  
  showList = JSON::parse(fetch("#{settings.sickBeard}#{sickbeard.searchTVDB}#{show}").body)
    
  error = ""
  results = {}
  
  if showList['results'].empty? then
    error = "Show not found"
  else
    results = showList['results']
  end
  
  haml :search, :locals => {:error => error, :results => results}
end

post '/add' do
  settings = Settings.new
  sickbeard = SickBeard.new
  
  # TODO: This is really hacky. Find a better way of passing both the show ID and name
  show = params[:show].split('----')
  
  chosenShowID = show[0]
  chosenShowName = show[1]
  
  base = Pathname.new("#{settings.basePath}")
  raise ArgumentError, 'Base path does not exist' if !base.directory?
  
  pathToShow = "#{settings.basePath}/#{chosenShowName}"
    
  path = Pathname.new(pathToShow)
  if !path.directory? then
    path.mkdir
  end
  
  addShowURL = "#{settings.sickBeard}#{sickbeard.addSingleShow}"
  
  response = fetch(addShowURL, {"whichSeries" => chosenShowID, "skipShow" => "0", "showToAdd" => pathToShow})
    
  case response
    when Net::HTTPSuccess     then "Show Added: #{chosenShowName}"
    else
      "#{response.error!}"
  end
end