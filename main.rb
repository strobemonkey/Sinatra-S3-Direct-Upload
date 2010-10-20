require 'rubygems'
require 'sinatra'
require 'active_support/core_ext'
require "base64"

get '/upload' do
  bucket            = 'bucket name here'
  access_key_id     = 'access key id here'
  secret_access_key = 'Enter secret access key here'

  key             = 'dev'
  acl             = 'public-read'
  expiration_date = 10.hours.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')
  max_filesize    = 2.gigabyte

  policy = Base64.encode64(
    "{'expiration': '#{expiration_date}',
      'conditions': [
        {'bucket': '#{bucket}'},
        ['starts-with', '$key', '#{key}'],
        {'acl': '#{acl}'},
        {'success_action_status': '201'},
        ['starts-with', '$Filename', ''],
        ['content-length-range', 0, #{max_filesize}]
      ]
    }").gsub(/\n|\r/, '')

  signature = Base64.encode64(
                OpenSSL::HMAC.digest(
                  OpenSSL::Digest::Digest.new('sha1'),
                  secret_access_key, policy)).gsub("\n","")

  @post = {
    "key" => "#{key}/${filename}",
    "AWSAccessKeyId" => "#{access_key_id}",
    "acl" => "#{acl}",
    "policy" => "#{policy}",
    "signature" => "#{signature}",
    "success_action_status" => "201"
  }

  @upload_url = "http://#{bucket}.s3.amazonaws.com/"
  haml :upload
end 

post '/upload' do
  
  params.inspect
  #probably want to do more things with the params, like add the file to a database, post process etc. 

end 

__END__

@@ layout
!!! 5
%html
  %head
    %title Sinatra AWS Upload Example
    %link{:rel => "stylesheet", :href => "http://cachedcommons.org/cache/blueprint/0.9.1/stylesheets/screen-min.css", :type => "text/css", :media =>"all"} 
    %link{:rel => "stylesheet", :href => "/css/swfupload.css", :type => "text/css", :media => "all"}
    %script{:src => "/js/swfupload/swfupload.js"}
    %script{:src => "http://ajax.googleapis.com/ajax/libs/jquery/1.4.3/jquery.min.js"}
    %script{:src => "http://cachedcommons.org/cache/jquery-swfupload/1.0.0/javascripts/jquery-swfupload-min.js"}

  %body
    = yield

@@ upload
:erb
  <script>
  $(function(){
      $('#swfupload-control').swfupload({
          // Backend Settings
          upload_url: "<%= @upload_url %>",    // Relative to the SWF file (or you can use absolute paths)
  			  http_success : [ 200, 201, 204 ], 		// FOR AWS
      
          // File Upload Settings
          file_size_limit : "102400", // 100MB
          file_types : "*.*",
          file_types_description : "All Files",
          file_upload_limit : "10",
          file_queue_limit : "0",
  			  file_post_name : "file", 				// FOR AWS
  
    			// Button settings
    			button_image_url : "/images/XPButtonUploadText_61x22.png",
    			button_placeholder_id : "spanButtonPlaceHolder",
    			button_width: 61,
    			button_height: 22,
      
          // Flash Settings
          flash_url : "/assets/swfupload.swf",
  			  debug: true,
  			  post_params: <%= @post.to_json %>		// FOR AWS
   
      }) 
          .bind('swfuploadLoaded', function(event){
      			$('#log').append('<li>Loaded</li>');
      		})
      		.bind('fileQueued', function(event, file){
      			$('#log').append('<li>File queued - '+file.name+'</li>');
      			// start the upload since it's queued
      			$(this).swfupload('startUpload');
      		})
      		.bind('fileQueueError', function(event, file, errorCode, message){
      			$('#log').append('<li>File queue error - '+message+'</li>');
      		})
      		.bind('fileDialogStart', function(event){
      			$('#log').append('<li>File dialog start</li>');
      		})
      		.bind('fileDialogComplete', function(event, numFilesSelected, numFilesQueued){
      			$('#log').append('<li>File dialog complete</li>');
      		})
      		.bind('uploadStart', function(event, file){
      			$('#log').append('<li>Upload start - '+file.name+'</li>');
      		})
      		.bind('uploadProgress', function(event, file, bytesLoaded){
      			$('#log').append('<li>Upload progress - '+bytesLoaded+'</li>');
      		})
      		.bind('uploadSuccess', function(event, file, serverData){
      			$('#log').append('<li>Upload success - '+file.name+'</li>');
      		})
      		.bind('uploadComplete', function(event, file){
      			$('#log').append('<li>Upload complete - '+file.name+'</li>');
      			 
      			// Change this callback function to suite your needs
      			 $.ajax({
               type: "POST",
               url: '/upload',
               data: "name=" + file.name,
               async: false,
             });
      			
      			// upload has completed, lets try the next one in the queue
      			$(this).swfupload('startUpload');
      		})
      		.bind('uploadError', function(event, file, errorCode, message){
      			$('#log').append('<li>Upload error - '+message+'</li>');
      		});
      
  });
  </script> 

%div{:id=> "swfupload-control"}
  %ol{:id=> "log"}
  %span{:id=> "spanButtonPlaceHolder"}