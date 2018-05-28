require 'bundler/setup'
require 'rubygems'
require 'json'
require 'date'
require 'sinatra'
require 'mongo'

# Set timezone to UTC as per spec
ENV['TZ'] = 'UTC'

# Sinatra Server Setup
port = ENV['PINGS_SERVER_PORT'] || 4567
puts "Starting Pings Server on Port #{port}"
set :port, port
set :bind, '0.0.0.0'

# Prints Erorr Message and Exits Server
def print_error_message_and_exit(e)
  puts "Error #{e.class}: #{e.message}"
  puts "Could not connect to MongoDB. " \
   "Please check an instance is running, with the correct port. " \
   "See README.md for further information."
  exit(1)
end

# Setup MongoDB connection
# We have a 30 second timeout before exiting.
mongo_uri = ENV['PINGS_SERVER_MONGO_URI'] || '127.0.0.1:27017'
begin
  client = Mongo::Client.new([mongo_uri], :database => 'pings')
  client.list_databases
rescue Mongo::Error::NoServerAvailable, Mongo::Error => e
  print_error_message_and_exit(e)
end
devices = client[:devices]
puts "Connected to MongoDB Server at #{mongo_uri}"

# Helper function converts ISO date formated strings
# or unix timestamp strings into Ruby DateTime objects
# params:
# => date_or_timestamp_string: string
# returns:
# => DateTime
def convert_date(date_or_timestamp_string)
  if /\d{4}\-\d{1,2}\-\d{1,2}/ =~ date_or_timestamp_string
    DateTime.strptime(date_or_timestamp_string, '%Y-%m-%d')
  else
    DateTime.strptime(date_or_timestamp_string, '%s')
  end
end

# Helper function to calculate the inclusive start and exclusive end
# timestamp.
# For example 2016-02-24 would be between 2016-02-24 00:00:00 UTC (inclusive)
#  and 2016-02-25 00:00:00 UTC (exclusive)
# params:
# => date: DateTime
# returns:
# => Hash: with "from" and "to" keys
def get_timestamp_range(date)
  # Simply convert date to timestamp for from timestamp
  from_timestamp = date.to_time.to_i

  # Add 1 day to date and then convert for "to" timestamp
  to_date = date.next_day(1)
  to_timestamp = to_date.to_time.to_i

  { from: from_timestamp, to: to_timestamp }
end

# Fetch list of unique devices
get '/devices' do
  content_type :json
  devices.find.distinct('device_id').to_json
end

# Fetch data for all devices and a specific date
get '/all/:date' do
  content_type :json
  date = convert_date(params[:date])

  # Calculate Date Range required
  range = get_timestamp_range(date)
  from = range[:from]
  to = range[:to]

  # Fetch Data and Group Results by Device ID
  devices
    .find({
      :timestamp => { :$gte => from, :$lt => to }
    })
    .map{|device| device}
    .compact
    .group_by{|d| d[:device_id]}
    .each{|_, v| v.map!{|entry| entry[:timestamp]}}
    .to_json
end

# Fetch data for specific device and date
get '/:device_id/:date' do
  content_type :json

  # Read Params
  device_id = params[:device_id]
  date = convert_date(params[:date])

  # Calculate Date Range required
  range = get_timestamp_range(date)
  from = range[:from]
  to = range[:to]

  # Fetch Data
  devices
    .find({
      :device_id => device_id,
      :timestamp => { :$gte => from, :$lt => to }
    })
    .map{|device| device[:timestamp]}
    .compact
    .to_json
end

# Fetch data for all devices during a specific time period
get '/all/:from/:to' do
  content_type :json

  # Read Params
  device_id = params[:device_id]
  from = convert_date(params[:from]).to_time.to_i
  to = convert_date(params[:to]).to_time.to_i

  # Fetch data and Group Results by Device ID
  devices
    .find({ :timestamp => { :$gte => from, :$lt => to } })
    .map{|device| device}
    .compact
    .group_by{|d| d[:device_id]}
    .each{|_, v| v.map!{|entry| entry[:timestamp]}}
    .to_json
end

# Fetch data for specific device during time period
get '/:device_id/:from/:to' do
  content_type :json

  # Read Params
  device_id = params[:device_id]
  from = convert_date(params[:from]).to_time.to_i
  to = convert_date(params[:to]).to_time.to_i

  # Fetch Data
  devices
    .find({
      :device_id => device_id,
      :timestamp => { :$gte => from, :$lt => to }
      })
    .map{|device| device[:timestamp]}
    .compact
    .to_json
end

# Clear all device data
post '/clear_data' do
  devices.delete_many()
  status 200
end

# Store device ping data
post '/:device_id/:epoch_time' do
  device_timestamp = {
    device_id: params['device_id'],
    timestamp: params['epoch_time'].to_i
  }
  devices.insert_one(device_timestamp)
  status 200
end
