require 'sinatra'
require 'pusher'
require 'sendgrid-ruby'
require 'json'
require 'securerandom'

Pusher.url = ENV["SENDGRID_PUSHER_URL"]

sendgrid = SendGrid::Client.new(api_user: ENV["SENDGRID_USERNAME"], api_key: ENV["SENDGRID_PASSWORD"])

get '/' do 
  @channel_name = SecureRandom.uuid
  erb :index
end

post '/notification' do 
  channel_name = params[:channel_name]
  channel = Pusher.channel_info(channel_name)

  if channel[:occupied]
    Pusher[channel_name].trigger('new_notification', {message: params[:message]})
  else
    email = SendGrid::Mail.new do |m|
      m.to      = params[:email]
      m.from    = 'no-reply@pusher.com'
      m.subject = "New Notification From Pusher"
      m.html    = 
      <<-MESSAGE 
      <p>Hey there!</p>

      <p> While you were offline, you received this notification: </p>

       <blockquote> <b>#{params[:message]}</b> </blockquote>

      <p>This was sent through http://pusher-sendgrid.herokuapp.com.</p>

      <p> You can follow the tutorial to add this nifty feature to your app <a href="http://blog.pusher.com/pusher-sendgrid">here</a>.</p>

      <p>Thanks!</p>

      <b>The Pusher Team</b>
      MESSAGE
    end
    sendgrid.send email
  end

  {success:200}.to_json

end