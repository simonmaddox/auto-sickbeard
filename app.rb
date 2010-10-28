require 'rubygems'
require 'sinatra'
require 'json'
require "net/http"
require "uri"
require "haml"
require "pathname"
require "cgi"
require "yaml"

class Settings
  attr_accessor :basePath, :sickBeard, :username, :password
  
  def initialize
    config = YAML.load(File.open('config/config.yml'))
    @basePath = config['basePath']
    @sickBeard = config['sickBeard']
    @username = config['username']
    @password = config['password']
  end
end

class SickBeard
  attr_accessor :addShows, :searchTVDB, :addSingleShow

  def initialize
    config = YAML.load(File.open('config/sickbeard.yml'))
    @addShows = config['addShows']
    @searchTVDB = config['searchTVDB']
    @addSingleShow = config['addSingleShow']
  end
end

# Original method from http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/classes/Net/HTTP.html
def fetch(uri, postData = {}, limit = 10)
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0
  
  settings = Settings.new
  
  uri = URI.parse(uri)
    
  http = Net::HTTP.new(uri.host, uri.port)  
  
  if postData.empty? then 
    request = Net::HTTP::Get.new(uri.request_uri)
    if !settings.username.nil? && settings.username.length > 0
      request.basic_auth(settings.username, settings.password)
    end
    response = http.request(request)
  else 
    request = Net::HTTP::Post.new(uri.request_uri)
    if !settings.username.nil? && settings.username.length > 0
      request.basic_auth(settings.username, settings.password)
    end
    request.set_form_data(postData)
    response = http.request(request)
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
    haml :error, :locals => {:error => error}
  elsif showList['results'].count == 1 then
    show = showList['results'][0]
    added = addShow(show[0], show[1])
    
    if added then
      "Show Added: #{show[1]}"
    end
  else
    results = showList['results']
    haml :search, :locals => {:error => error, :results => results}
  end
end

post '/add' do
  # TODO: This is really hacky. Find a better way of passing both the show ID and name
  show = params[:show].split('----')
  added = addShow(show[0], show[1])
  
  if added then
    haml :success, :locals => {:show => show[1]}
  end
    
end

def addShow(chosenShowID, chosenShowName)
  settings = Settings.new
  sickbeard = SickBeard.new
  
  base = Pathname.new("#{settings.basePath}")
  raise ArgumentError, 'Base path does not exist. Check config/config.yml' if !base.directory?
  
  pathToShow = "#{settings.basePath}/#{chosenShowName}"
    
  path = Pathname.new(pathToShow)
  if !path.directory? then
    path.mkdir
  end
  
  addShowURL = "#{settings.sickBeard}#{sickbeard.addSingleShow}"
  
  response = fetch(addShowURL, {"whichSeries" => chosenShowID, "skipShow" => "0", "showToAdd" => pathToShow})
    
  case response
    when Net::HTTPSuccess     then true
    else
      "#{response.error!}"
  end
end