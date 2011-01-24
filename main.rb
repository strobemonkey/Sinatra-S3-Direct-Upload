require 'rubygems'
require 'sinatra'
require 'active_support/core_ext'   
require 'openssl'
require 'base64'

set :bucket, 'bucket name here'
set :access_key_id, 'access key id here'
set :secret_access_key, 'Enter secret access key here'
set :key, 'dev'

get '/upload' do

  acl = 'public-read'
  expiration_date = 10.hours.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')
  max_filesize = 2.gigabyte

  policy = Base64.encode64(
    "{'expiration': '#{expiration_date}',
      'conditions': [
      {'bucket': '#{settings.bucket}'},
      ['starts-with', '$key', '#{settings.key}'],
      {'acl': '#{acl}'},
      {'success_action_status': '201'},
      ['starts-with', '$Filename', ''],
      ['content-length-range', 0, #{max_filesize}]
      ]
      }"
  ).gsub(/\n|\r/, '') 

  signature = Base64.encode64(
    OpenSSL::HMAC.digest(
    OpenSSL::Digest::Digest.new('sha1'),
    settings.secret_access_key, policy)
  ).gsub("\n","")  

  @post = {
    "key" => "#{settings.key}/${filename}",
    "AWSAccessKeyId" => "#{settings.access_key_id}",
    "acl" => "#{acl}",
    "policy" => "#{policy}",
    "signature" => "#{signature}",
    "success_action_status" => "201"
  }

  @upload_url = "http://#{settings.bucket}.s3.amazonaws.com/"
  haml :upload
end

post '/upload' do
  
  params.inspect
  #probably want to do more things with the params, like add the file to a database, post process etc.

end 