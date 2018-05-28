# Tanda Pings Coding Challenge

## Installation
First we need to install the required ruby packages in a local bundle.
We require `bundler` for this.

```
$ gem install bundler
$ bundle install --path vendor/bundle
```

## Running the MongoDB Server
The API server uses a mongodb instance running on port 27017
to store the underlying data.

If the docker process is stopped the data will be lost, but for the purposes
of this exercise that should be okay. This is easily overcome for
production environments by having data sorted on persistent volumes.

An easy way to get a mongo instance running is to use Docker.
Docker is not required, any other way of running a mongodb instance is okay.
The following script will pull the mongo Docker image and
run into in detached mode, exposing port 271017.
```
$ docker run -d -p 27017:27017 --name pings-mongodb mongo:3.4
```

## Running API Server
The server runs on port 4567
```
$ bundle exec server.rb
```

## Running the Pings Test
```
$ ruby pings.rb
```

## Technical Discussion
### Data Storage Decisions
As per the specification an in-memory storage was not acceptable. I quickly
ruled out writing to files as that solution doesn't scale beyond the initial
task.

I decided to use MongoDB for a couple of reasons.
- It quickly solves the provided task in soring JSON key-value
(device-id -> timestamp) object.
- A NoSQL solution would be very applicable in scaling and production going
forward with additional requirements.
- Finally, I hadn't used a NoSQL database in a few years so why not?

Either NoSQL or SQL solutions would be acceptable and scalable in production
environments.

## Knowledge Acquired
### Ruby
This was the first time I've ever used Ruby. So I'm sure there are cleaner ways
to write certain functions and operations;
but I am not familar enough with the syntax to comment further.

### Mongodb
I've only used Mongo a handful of times a few years ago, so was interesting
trying it out again. It's fairly straightforward to get started, I'm sure I
could dive deeper into the API and improvement the queries' readability and
efficiency.

## Potential Improvements
### Caching
Currently each API request hits the database.
It would be fairly easy to implement a caching layer which can be invalidated
on certain database operations such as Modifications, Inserts, Deletions.

### Error Handling
The server does not currently handle any errors properly. It assumes all
requests are in the correct format. This obviously isn't ideal or production
ready.

### Data Storage Format
Ping data is currently stored as a list of tuples (device_id, timestamp),
depending on the full requirements you would want some more structure around
the data.

### Project Structure
The server was implemented in a single file, for the purposes of this exercise
this seems accpetable because it is very simple. That being said some functions  
are shared, and could be put in a utils.rb file. If you were to extend
this it would make sense to add proper structure around the server.

### HTTPS
All server/client communication should be done securely, it was skipped for
the purpose of this task for simplicity.

### Database Security
Currently the MongoDB is setup without any authentication required (again for
simplicity). There is also no data security, or user authentication required
to access certain device IDs, etc. In production this would be unacceptable.


## My Details
- [GitHub Profile](https://github.com/aaronhayes)
- [LinkedIn Profile](https://www.linkedin.com/in/aaronhayes1/)
- [Email Me](mailto:aaron.hayes@bigpond.com)
