#encoding: utf-8
require 'rubygems'

require 'sinatra'
require 'sinatra/assetpack'
require 'sinatra/base'

require 'sinatra_more/markup_plugin'
require 'sinatra/seo'

require 'dalli'
require 'pony'
require 'erb'

class SinatraApp < Sinatra::Base
	register Sinatra::AssetPack
  	register SinatraMore::MarkupPlugin
  	register Sinatra::Seo

	set :root, File.dirname(__FILE__)
	set :views, Proc.new { File.join(root, "app/templates") }
  	set :public_folder, Proc.new { File.join(root, "app/assets") }
  	set :seo_file, File.join(File.dirname(__FILE__), 'app/config/site.seo')

  	set :cache, Dalli::Client.new(nil, {:expires_in => 60*10})
  	set :enable_cache, true
	set :short_ttl, 400
	set :long_ttl, 4600

  	before do
  		headers "Content-Type" => "text/html; charset=utf-8"
  	end

  	helpers do
  		def cache_for(mins = 1)
			if settings.environment != :development
				response['Cache-Control'] = "public, max-age=#{60*mins}"
			end
		end
	end


  	assets {
    	serve '/javascripts', from: 'app/assets/javascripts'
    	serve '/stylesheets', from: 'app/assets/stylesheets'
    	serve '/images', from: 'app/assets/images'

	    css :application, 
			'/stylesheets/application.css', 
			[
			'/stylesheets/bootstrap.min.css',
			'/stylesheets/bootstrap-responsive.min.css',
			'/stylesheets/custom.css'
			]

		js :application, 
			'/javascripts/application.js', 
			[
			'/javascripts/bootstrap.min.js',
			'/javascripts/custom.js'
			]

		js :jquery, '/javascripts/jquery.min.js', ['/javascripts/jquery-1.8.2-min.js']

	    #js_compression  :jsmin      # Optional
	    #css_compression :sass       # Optional
  	}


	get '/' do
		puts seo
		@title = seo.index.title
		begin
			content = settings.cache.get("website")
		rescue DalliError, NetworkError => e
			content = erb(:index)
			settings.cache.set("website", content)
		end
		erb(:index, :val => content)
	end

	# email with Ponny
	post '/contact' do
		
		name      		= params[:rsvp][:name]
		
		Pony.mail(
		:name => name,
		:mail => email,
		:from => email,
		:to => 'destinary@email.com',
		:subject =>"Subject",
		:body => "
				 Name: #{name}\n
				 E-mail: #{email}\n
				 ",
		:port => '587',
		:via => :smtp,
		:via_options => { 
		:address              => 'smtp.gmail.com', 
		:port                 => '587', 
		:enable_starttls_auto => true, 
		:user_name            => 'email@email.com', 
		:password             => 'password', 
		:authentication       => :plain, 
		:domain               => 'currentdomain.com'
		})

		return true
		
	end
end