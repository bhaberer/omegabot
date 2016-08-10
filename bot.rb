# -*- coding: utf-8 -*-
require 'rubygems'
require 'bundler/setup'

require 'cinch'
require 'psych'
require 'cinch-logger-canonical'
require 'cinch-radiomega'
require 'cinch-hangouts'
require 'cinch-seen'
#require 'cinch-twitch'
require 'cinch-notes'

# Load the bot config
conf = Psych.load(File.open('config/bot.yml'))

# Init Bot
@bot = Cinch::Bot.new do
  configure do |c|
    # Base Config
    c.nick         = conf[:nick]
    c.server       = conf[:server]
    c.channels     = conf[:chans].map { |chan| '#' + chan }
    c.max_messages = 1
    c.port       = conf[:port] if conf.key?(:port)

    # Plugins
    c.plugins.prefix  = '.'
    c.plugins.plugins =
      Cinch::Plugins.constants.map do |plugin|
        Class.module_eval("Cinch::Plugins::#{plugin}")
      end

    c.plugins.options[Cinch::Plugins::Radiomega] = { host: 'http://radiomega.herokuapp.com' }
    #c.plugins.options[Cinch::Plugins::TwitchTV] = { streamid: 'omegadaz' }
  end

  on :channel, /\A\.stats\z/ do |m|
    if conf.key?(:stats_url)
      m.user.send 'The stats for the channel are available at: ' +
                  conf[:stats_url]
    else
      m.user.send 'No stats page has been defined for this channel, sorry!'
    end
  end

  on :channel, /\A\.help\z/ do |m|
    m.user.send 'Hello, my name is #{conf[:nick]}, and I\'m ' +
                "the #{m.channel.name} bot."
    if conf.key?(:wiki_url)
      m.user.send 'You can find out more about me and how to file feature' +
                  "requests / bugs by visiting #{conf[:wiki_url]}"
    end
  end

  on :notice, /IDENTIFY/ do |m|
    m.reply "IDENTIFY #{conf[:nickserv_pass]}" if m.user.nick == 'NickServ'
  end
end

# Loggers
if conf.key?(:logging) && defined? Cinch::Logger::CanonicalLogger
  conf[:logging].each do |channel|
    @bot.loggers << Cinch::Logger::CanonicalLogger.new(channel, @bot)
  end
end

@bot.start
