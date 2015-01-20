#!/usr/bin/ruby
# Generate a test plan for each concurrency level given in the arg list
# Example: ruby flood.rb 50 100 200

require 'rubygems'
require 'ruby-jmeter'

HOST = 'localhost'
PROTOCOL = 'http'
PORT = '8080'
TOKEN = 'afc0a6c8c73211e3aaf844fb42fffe8c'

#HOST = 'aimprod.medullan.com'
#PROTOCOL = 'https'
#PORT = '443'
#TOKEN = 'c6002a7018be11e48c210800200c9a66'
LOOPS = 1  #this was orignally 100, should play with this number to see how the perf test responds

loads = ARGV.map {|c| c.to_i }
loads.each do |c|

  test do
    threads :count => c, :loops => LOOPS, :rampup => c, :scheduler => false do

      hash_to_querystring = lambda { |hash| 
        hash.keys.inject('') do |query_string, key|
          query_string << '&' unless key == hash.keys.first
          query_string << "#{URI.encode(key.to_s)}=#{hash[key]}"
        end
      }

      defaults({
        :domain => HOST, :protocol => PROTOCOL, :port => PORT,
        :connect_timeout => '3000', :response_timeout => '10000'
      })
      #header [{:name => 'Content-Type', :value => 'application/json'}]

      random_variable :variableName => 'client_id', :minimumValue => 99999999, :maximumValue => 999999999
      random_variable :variableName => 'ip1', :minimumValue => 1, :maximumValue => 127
      random_variable :variableName => 'ip2', :minimumValue => 1, :maximumValue => 127
      random_variable :variableName => 'ip3', :minimumValue => 1, :maximumValue => 127
      random_variable :variableName => 'ip4', :minimumValue => 1, :maximumValue => 127

      # Identify the user by member id, and extract profile_id

      params = {
        :dataset => TOKEN,
        :member_id => '${__UUID()}'
      }

      visit :name => 'IDENTIFY', :url => '/meda/identify.gif?' + hash_to_querystring.call(params), :use_keepalive => 'true' do
        extract :name => 'profile_id', :regex => %q{.*_meda_profile_id=([^;]+).*}, :useHeaders => 'true'
      end

      #think_time 100, 300
      # Add profile attributes

      params = {
        :dataset => TOKEN,
        :profile_id => '${profile_id}',
        :age => "${__Random(18,100)}",
        :weight => "${__Random(90,200)}",
        :some_long_string_key_1 => "dfskjdhfsdk",
        :some_long_string_key_2 => "sdjahskjsahdas",
        :some_long_string_key_3 => "sajdhaksd",
        :some_long_string_key_4 => "asjkdhas",
        :some_long_string_key_5 => "dsfjkdshf",
        :some_long_string_key_6 => "sdhf",
        :some_long_string_key_7 => "sdkfjhdsfdsfhdsf",
        :some_long_string_key_8 => "sdkjfdsfdsfdsf"
      }
      visit :name => 'PROFILE', :url => '/meda/profile.gif?' + hash_to_querystring.call(params), :use_keepalive => 'true'

      # Record 10 pageviews

      params = {
        :dataset => TOKEN,
        :profile_id => '${profile_id}',
        :client_id => '${client_id}',
        :hostname => 'https://www.example.com',
        :user_ip => "${ip1}.${ip2}.${ip3}.${ip4}",
        :referrer => 'https://www.medullan.com',
        :title => URI.encode("Page Title ") + '${__Random(1,999999999)}',
        :path => "/${__Random(1,99)}/${__Random(1,99)}/${__Random(1,99)}.html"
      }
      10.times do
        #think_time 100, 500
        visit :name => 'PAGE', :url => '/meda/page.gif?' + hash_to_querystring.call(params), :use_keepalive => 'true'
      end

      # Record 10 events

      params = {
        :dataset => TOKEN,
        :profile_id => '${profile_id}',
        :client_id => '${client_id}',
        :hostname => 'https://www.example.com',
        :user_ip => "${ip1}.${ip2}.${ip3}.${ip4}",
        :referrer => 'https://www.medullan.com',
        :title => URI.encode("Page Title ") + '${__Random(1,999999999)}',
        :path => "/${__Random(1,99)}/${__Random(1,99)}/${__Random(1,99)}.html",
        :category => 'Category',
        :action => 'Action',
        :label => 'Label',
        :value => '100'
      }
      10.times do
        #think_time 200, 1000
        visit :name => 'EVENT', :url => '/meda/track.gif?' + hash_to_querystring.call(params), :use_keepalive => 'true'
      end

    end
  end.run(
    debug: true,
    file: "perf/results/perf_test_#{c}.jmx",
    log: "perf/results/perf_test_#{c}_results.log",
    jtl: "perf/results/perf_test_#{c}_results.jtl"
  )

end


