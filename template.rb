# Application Generator Template
# Usage: rails new app_name -m http://github.com/fortuity/rails3-mongoid-devise/raw/master/template.rb

# Based on: http://github.com/fortuity/rails3-mongoid-devise/

# If you are customizing this template, you can use any methods provided by Thor::Actions
# http://rdoc.info/rdoc/wycats/thor/blob/f939a3e8a854616784cac1dcff04ef4f3ee5f7ff/Thor/Actions.html
# and Rails::Generators::Actions
# http://github.com/rails/rails/blob/master/railties/lib/rails/generators/actions.rb

def console_log(msg)
  say "\n    #{msg}", :yellow
end

console_log "Modifying a new Rails app..\n"

#----------------------------------------------------------------------------
# Configure
#----------------------------------------------------------------------------

# haml_flag = yes?('Would you like to use the Haml template system? (yes/no)')
haml_flag = true
# jquery_flag = yes?('Would you like to use jQuery instead of Prototype? (yes/no)')
jquery_flag = true

heroku_flag = yes?('Heroku gem? (y/n)')
ey_flag = yes?('Engine Yard gem? (y/n)')
mongo_flag = yes?('Use Mongo? (y/n)')
ban_spiders_flag = yes?('Ban spiders? (y/n)')

#----------------------------------------------------------------------------
# Capistrano
#----------------------------------------------------------------------------
console_log "Adding capistrano gem support"
gem "capistrano"
gem "capistrano-ext"
run 'bundle install'
capify!
run "mkdir -p config/deploy"
run "touch config/deploy/development.rb"
run "touch config/deploy/staging.rb"
run "touch config/deploy/production.rb"

#----------------------------------------------------------------------------
# Staging environment
#----------------------------------------------------------------------------
console_log "Adding staging environment support"
run "cp config/environments/development.rb config/environments/staging.rb"
append_file 'config/database.yml' do
  <<-CONFIG

staging:
  adapter: sqlite3
  database: db/staging.sqlite3
  pool: 5
  timeout: 5000
CONFIG
end

#----------------------------------------------------------------------------
# Set up git
#----------------------------------------------------------------------------
console_log "setting up source control with 'git'..."
# specific to Mac OS X
append_file '.gitignore' do
  '.DS_Store'
end
git :init
git :add => '.'
git :commit => "-m 'Initial commit of unmodified new Rails app'"

#----------------------------------------------------------------------------
# Remove the usual cruft
#----------------------------------------------------------------------------
console_log "removing unneeded files..."
run 'rm public/index.html'
run 'rm public/favicon.ico'
run 'rm public/images/rails.png'
run 'rm README'
run 'touch README'

if ban_spiders_flag
  console_log "banning spiders from your site by changing robots.txt..."
  gsub_file 'public/robots.txt', /# User-Agent/, 'User-Agent'
  gsub_file 'public/robots.txt', /# Disallow/, 'Disallow'
end

#----------------------------------------------------------------------------
# Heroku Option
#----------------------------------------------------------------------------
if heroku_flag
  console_log "adding Heroku gem to the Gemfile..."
  gem 'heroku', '1.10.6', :group => :development
end

#----------------------------------------------------------------------------
# Engine Yard Option
#----------------------------------------------------------------------------
if ey_flag
  console_log "adding Engine Yard gem to the Gemfile..."
  gem 'engineyard', :group => :development
end

#----------------------------------------------------------------------------
# Haml Option
#----------------------------------------------------------------------------
if haml_flag
  console_log "setting up Gemfile for Haml..."
  append_file 'Gemfile', "\n# Bundle gems needed for Haml\n"
  gem 'haml', '3.0.18'
  gem 'haml-rails', '0.2', :group => :development
  # the following gems are used to generate Devise views for Haml
  gem 'hpricot', '0.8.2', :group => :development
  gem 'ruby_parser', '2.0.5', :group => :development
end

#----------------------------------------------------------------------------
# jQuery Option
#----------------------------------------------------------------------------
if jquery_flag
  gem 'jquery-rails', '0.1.3'
end

#----------------------------------------------------------------------------
# Set up Mongoid
#----------------------------------------------------------------------------
if mongo_flag
  console_log "setting up Gemfile for Mongoid..."
  gsub_file 'Gemfile', /gem \'sqlite3-ruby/, '# gem \'sqlite3-ruby'
  append_file 'Gemfile', "\n# Bundle gems needed for Mongoid\n"
  gem "mongoid", "2.0.0.beta.19"
  gem 'bson_ext', '1.1'

  console_log "installing Mongoid gems (takes a few minutes!)..."
  run 'bundle install'

  console_log "creating 'config/mongoid.yml' Mongoid configuration file..."
  run 'rails generate mongoid:config'

  console_log "modifying 'config/application.rb' file for Mongoid..."
  gsub_file 'config/application.rb', /require 'rails\/all'/ do
  <<-RUBY
  # If you are deploying to Heroku and MongoHQ,
  # you supply connection information here.
  require 'uri'
  if ENV['MONGOHQ_URL']
    mongo_uri = URI.parse(ENV['MONGOHQ_URL'])
    ENV['MONGOID_HOST'] = mongo_uri.host
    ENV['MONGOID_PORT'] = mongo_uri.port.to_s
    ENV['MONGOID_USERNAME'] = mongo_uri.user
    ENV['MONGOID_PASSWORD'] = mongo_uri.password
    ENV['MONGOID_DATABASE'] = mongo_uri.path.gsub('/', '')
  end

  require 'mongoid/railtie'
  require 'action_controller/railtie'
  require 'action_mailer/railtie'
  require 'active_resource/railtie'
  require 'rails/test_unit/railtie'
  RUBY
  end
  #----------------------------------------------------------------------------
  # Tweak config/application.rb for Mongoid
  #----------------------------------------------------------------------------
  gsub_file 'config/application.rb', /# Configure the default encoding used in templates for Ruby 1.9./ do
  <<-RUBY
  config.generators do |g|
        g.orm             :mongoid
      end

      # Configure the default encoding used in templates for Ruby 1.9.
  RUBY
  end
end

console_log "prevent logging of passwords"
gsub_file 'config/application.rb', /:password/, ':password, :password_confirmation'

#----------------------------------------------------------------------------
# Set up jQuery
#----------------------------------------------------------------------------
if jquery_flag
  run 'rm public/javascripts/rails.js'
  console_log "replacing Prototype with jQuery"
  # "--ui" enables optional jQuery UI
  run 'rails generate jquery:install --ui'
end

#----------------------------------------------------------------------------
# Set up Devise
#----------------------------------------------------------------------------
console_log "setting up Gemfile for Devise..."
append_file 'Gemfile', "\n# Bundle gem needed for Devise\n"
gem 'devise', '1.1.3'

console_log "installing Devise gem (takes a few minutes!)..."
run 'bundle install'

console_log "creating 'config/initializers/devise.rb' Devise configuration file..."
run 'rails generate devise:install'
run 'rails generate devise:views'
console_log "creating a User model and modifying routes for Devise..."
run 'rails generate devise user'

#----------------------------------------------------------------------------
# Envronments & Mailers
#----------------------------------------------------------------------------
console_log "modifying environment configuration files..."
gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send/, '### ActionMailer Config'
gsub_file 'config/environments/development.rb', /config.action_mailer.raise_delivery_errors = false/ do
<<-RUBY
config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  # A dummy setup for development - no deliveries, but logged
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"
RUBY
end

# gsub_file 'config/environments/production.rb', /config.i18n.fallbacks = true/ do
# <<-RUBY
# config.i18n.fallbacks = true
#   
#   config.action_mailer.default_url_options = { :host => 'yourhost.com' }
#   ### ActionMailer Config
#   # Setup for production - deliveries, no errors raised
#   config.action_mailer.delivery_method = :smtp
#   config.action_mailer.perform_deliveries = true
#   config.action_mailer.raise_delivery_errors = false
#   config.action_mailer.default :charset => "utf-8"
# RUBY
# end

#----------------------------------------------------------------------------
# Create a home page
#----------------------------------------------------------------------------
console_log "create a home controller and view"
generate(:controller, "home index")
gsub_file 'config/routes.rb', /get \"home\/index\"/, 'root :to => "home#index"'

console_log "set up a simple demonstration of Devise"
gsub_file 'app/controllers/home_controller.rb', /def index/ do
<<-RUBY
def index
    @users = User.all
RUBY
end

if haml_flag
  run 'rm app/views/home/index.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/home/index.html.haml' do 
<<-'FILE'
- @users.each do |user|
  %p User: #{link_to user.email, user}
FILE
  end
else
  append_file 'app/views/home/index.html.erb' do <<-FILE
<% @users.each do |user| %>
  <p>User: <%=link_to user.email, user %></p>
<% end %>
  FILE
  end
end

#----------------------------------------------------------------------------
# Create a users page
#----------------------------------------------------------------------------
generate(:controller, "users show")
gsub_file 'config/routes.rb', /get \"users\/show\"/, '#get \"users\/show\"'
gsub_file 'config/routes.rb', /devise_for :users/ do
<<-RUBY
devise_for :users
  resources :users, :only => :show
  
  devise_scope :user do
    get "register"  => "devise/registrations#new" 
    get "login"  => "devise/sessions#new"    
    get "logout" => "devise/sessions#destroy"
  end 
RUBY
end

gsub_file 'app/controllers/users_controller.rb', /def show/ do
<<-RUBY
before_filter :authenticate_user!

  def show
    @user = User.find(params[:id])
RUBY
end

if haml_flag
  run 'rm app/views/users/show.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/users/show.html.haml' do <<-'FILE'
%p
  User: #{@user.email}
  FILE
  end
else
  append_file 'app/views/users/show.html.erb' do <<-FILE
<p>User: <%= @user.email %></p>
  FILE
  end
end

if haml_flag
  create_file "app/views/devise/menu/_login_items.html.haml" do <<-'FILE'
- if user_signed_in?
  %li
    = link_to('Logout', destroy_user_session_path)
- else
  %li
    = link_to('Login', new_user_session_path)
  FILE
  end
else
  create_file "app/views/devise/menu/_login_items.html.erb" do <<-FILE
<% if user_signed_in? %>
  <li>
  <%= link_to('Logout', destroy_user_session_path) %>        
  </li>
<% else %>
  <li>
  <%= link_to('Login', new_user_session_path)  %>  
  </li>
<% end %>
  FILE
  end
end

if haml_flag
  create_file "app/views/devise/menu/_registration_items.html.haml" do <<-'FILE'
- if user_signed_in?
  %li
    = link_to('Edit account', edit_user_registration_path)
- else
  %li
    = link_to('Sign up', new_user_registration_path)
  FILE
  end
else
  create_file "app/views/devise/menu/_registration_items.html.erb" do <<-FILE
<% if user_signed_in? %>
  <li>
  <%= link_to('Edit account', edit_user_registration_path) %>
  </li>
<% else %>
  <li>
  <%= link_to('Sign up', new_user_registration_path)  %>
  </li>
<% end %>
  FILE
  end
end

#----------------------------------------------------------------------------
# Generate Application Layout
#----------------------------------------------------------------------------
console_log "Setting up default nifty layout"

# remove standard layout
run 'rm app/views/layouts/application.html.erb'

# generate a new one
append_file 'Gemfile', "\n# Bundle gems needed for Nifty Generators\n"
gem "nifty-generators"
run 'bundle install'

if haml_flag
  run "rails generate nifty:layout --haml"
else
  run "rails generate nifty:layout"
end


#----------------------------------------------------------------------------
# Add Stylesheets
#----------------------------------------------------------------------------
create_file 'public/stylesheets/application.css' do <<-FILE
ul.hmenu {
  list-style: none;	
  margin: 0 0 2em;
  padding: 0;
}

ul.hmenu li {
  display: inline;  
}
FILE
end

#----------------------------------------------------------------------------
# Create a default user
#----------------------------------------------------------------------------
console_log "creating a default user"
if mongo_flag
  append_file 'db/seeds.rb' do <<-FILE
  puts 'EMPTY THE MONGODB DATABASE'
  Mongoid.master.collections.reject { |c| c.name == 'system.indexes'}.each(&:drop)
  puts 'SETTING UP DEFAULT USER LOGIN'
  user = User.create!(:email => 'admin@test.com', :password => 'adminuser', :password_confirmation => 'adminuser')
  puts 'New user created: ' << user.email
  FILE
  end
else
  append_file 'db/seeds.rb' do <<-FILE
  puts 'SETTING UP DEFAULT USER LOGIN'
  user = User.create!(:email => 'admin@test.com', :password => 'adminuser', :password_confirmation => 'adminuser')
  puts 'New user created: ' << user.email
  FILE
  end
end

run 'rake db:migrate' unless mongo_flag
run 'rake db:seed'

#----------------------------------------------------------------------------
# Finish up
#----------------------------------------------------------------------------
console_log "checking everything into git..."
git :add => '.'
git :commit => "-am 'modified Rails app completed via template generation'"

console_log "Done setting up your Rails app"