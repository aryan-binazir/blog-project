require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, "secret"
  set :erb, escape_html: true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end


helpers do
  def authorized_user?(post)
    session[:signed_in] && (post[:blogger_id] == session[:signed_in_id])
  end

  def get_last_post_id(user_id)
    @storage.get_last_post_id(user_id)
  end
end

before do
  @storage = DatabasePersistence.new(logger)
end

# Default route, bypassed if user signed in
get "/" do
  # Automatically bypass this page if already signed in
  if session[:signed_in]
    redirect "/blogs"
  else  
    erb :landing_page, layout: :layout
  end
end

# Add user
post "/blogs/users/add" do
  user_name = params[:user_name]
  password = params[:password]
  blog_name = params[:blog_name]
  log_in = user_name.downcase!
  @storage.add_user_blog(user_name, password, blog_name)
  session[:success] = "Your account has successfully been created."
  redirect "/blogs/sign_in"
end

# View list of lists
get "/blogs" do
  @blogs = @storage.get_list_of_users_and_blogs
  erb :blog_page_general, layout: :layout
end

# Sign in form post
post "/blogs/sign_in" do
  log_in = params[:user_name].strip
  password = params[:password].strip
  user = @storage.retrieve_password_for_user(log_in)
  if (user[:password] == password)
    session[:success] = "Welcome, #{log_in}."
    session[:signed_in] = true
    session[:signed_in_id] = user[:id].to_s
    redirect session.delete(:redirect)
  else
    session[:error] = "Your user name and/or password were incorrect."
    redirect "/blogs/sign_in"
  end
end

# Sign in page
get "/blogs/sign_in" do
  erb :sign_in_page, layout: :layout
end

# Get specific blog
get "/blogs/:id" do
  id = params[:id]
  @user = @storage.find_user(id)
  @posts = @storage.find_posts_by_user(id)
  erb :blog_posts_for_user, layout: :layout
end

# Sign out
post "/blogs/sign_out" do
  session[:signed_in] = false
  session[:signed_in_id] = false
  session[:success] = "You have successfully been signed out."
  redirect "/"
end

# Delete account
post "/blogs/delete_account/:id" do
  id = params[:id]
  session[:signed_in] = false
  session[:signed_in_id] = false
  session[:success] = "Your account has been deleted."
  @storage.delete_account(id)
  redirect "/"
end

# View specific post
get "/blogs/posts/:post_id" do
  post_id = params[:post_id]
  @post = @storage.find_post_by_id(post_id)
  erb :single_post, layout: :layout
end

# Edit a specific post first page
get "/blogs/posts/edit/:post_id" do
  post_id = params[:post_id]
  @post = @storage.find_post_by_id(post_id)
  if (authorized_user?(@post))
    erb :edit_page, layout: :layout
  else
    session[:error] = "You need to be logged in to the correct account to edit a page."
    session[:redirect] = "/blogs/posts/edit/#{post_id}"
    redirect '/blogs/sign_in'
  end
end

# Edit a specific post submit
post "/blogs/posts/edit/:post_id" do
  # HANDLE LATER
  post_id = params[:post_id]
  title = params[:title]
  date = params[:date]
  text = params[:text]
  @storage.update_post(title, date, text, post_id)
  redirect "/blogs/posts/edit/#{post_id}/upload"
end

# Photo edit upload page
get "/blogs/posts/edit/:post_id/upload" do
  @post_id = params[:post_id]
  erb :upload_edit_photo, layout: :layout
end

# Submit for sign in
post "/blogs/sign_in" do
  log_in = params[:user_name].strip
  password = params[:password].strip
  user = @storage.retrieve_password_for_user(log_in)
  if (!user[:no_user] && user[:password] == password)
    session[:success] = "Welcome, #{log_in}."
    session[:signed_in] = true
    session[:signed_in_id] = user[:id].to_s
    redirect session[:redirect]
  else
    session[:error] = "Your user name and/or password were incorrect."
    redirect "/blogs/sign_in"
  end
end

# Load add post page
get "/blogs/:id/posts/add" do
  erb :add_post, layout: :layout 
end

# Load add post page
post "/blogs/:id/posts/add" do
  blogger_id = params[:id]
  title = params[:title]
  date = params[:date]
  text = params[:text]
  @storage.add_post(title, date, text, blogger_id)
  @post_id = get_last_post_id(blogger_id)
  puts @post_id
  erb :upload_add_photo, layout: :layout
end

# Delete a specific post
post "/blogs/posts/delete/:post_id" do
  post_id = params[:post_id]
  @post = @storage.find_post_by_id(post_id)
  if (authorized_user?(@post))
    @storage.delete_post(post_id)
    session[:success] = "Your post has been deleted."
    redirect "/blogs/#{@post[:blogger_id]}"
  else
    session[:error] = "You need to be logged in to the correct account to delete a page."
    redirect '/blogs/sign_in'
  end
end

# upload a photo
post "/blogs/posts/edit/:post_id/upload" do
  post_id = params[:post_id]
  if params[:image][:filename] && params[:image]
    filename = params[:image][:filename]
    file = params[:image][:tempfile]
    path = "./public/images/#{filename}"

    
    File.open(path, 'wb') do |f|
      f.write(file.read)
    end
  end
  @storage.change_photo(filename, post_id)
  session[:success] = 'Your post has been edited.'
  redirect "/blogs/posts/#{post_id}"
end