require 'bundler/setup'
Bundler.require

require 'dotenv'
Dotenv.load('./.env')

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: "db/development.sqlite3"
)

ActiveRecord::Base.logger = Logger.new(STDOUT)

require_all 'app'



require 'open-uri'
require 'json'
require 'rest-client'
require 'net/http'
require 'awesome_print'
require 'uri'
require 'openssl'
require 'mini_magick'
require 'bcrypt'
require 'tty-prompt'
require 'twitter'
require 't'
require 'tco'
require 'rmagick'
require 'catpix'
require 'dotenv'
# require 'image_optimizer'
