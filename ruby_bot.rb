#!/usr/bin/env ruby

require "socket"

OWNER = "l3thal"
HOST  = "smashthestack.org"

class IRC

  def initialize(server, port, nick, channel)
    @server = server
    @port = port
    @nick = nick
    @channel = channel
  end

  def send(s)
    puts "[+] #{s}"
    @irc.send "#{s}\n", 0 
  end

  def connect
    @irc = TCPSocket.open(@server, @port)
    send "USER blah blah blah :blah blah"
    send "NICK #{@nick}"
    sleep 2
    send "JOIN #{@channel}"    
  end

  def doit(s)
    eval(s).to_s
  end

  def handle_input(s, q={})
    # TODO: This is ugly... find a better way to handle this
    case s.strip
    when /^PING :(.+)$/i
       send "PONG :#{$1}"
    when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+?)\s:hi\s#{@nick}$/i
      send "PRIVMSG #{$4} :heya #{$1}!"
    when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+?)\s:!po0f\s(.+?)$/i
      q[:u], q[:h] = $1, $3
      send "KICK #{$4} #{$5}" if approved?(q)
      send "PRIVMSG #{$4}" if !approved?(q)
    when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.(.+?)\s:!op\s(.+?)$/i
      q[:u], q[:h] = $1, $3 
      send "MODE ##{$4} +o #{$5}" if approved?(q)      
      send "PRIVMSG #{$4} :Nope xD" if !approved?(q)
    when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+?)\s:!version$/i
      send "NOTICE #{(($4==@nick)?$1:$4)} :\001VERSION ruby_bot v0.0001a by l3thal@smashthestack.org"
    when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+")\s:!do (.+?)$/i
      q[:u], q[:h] = $1, $3
      send "PRIVMSG #{$1} :#{doit($5)}" if approved?(q)
    else
      puts s
    end
  end

  def approved?(q)
    return true if q[:u] == OWNER && q[:h] == HOST
  end    

  def run
    loop do
      ready = select([@irc, $stdin], nil, nil, nil)
      next if !ready
      for s in ready[0]
        if s == $stdin then
          return if $stdin.eof
          s = $stdin.gets
          send s
        elsif s == @irc then
          return if @irc.eof
          s = @irc.gets
          handle_input(s)
        end
      end
    end
  end
end

irc = IRC.new('irc.smashthestack.org', 6667, 'ruby_bot', '#boo1')
irc.connect
begin
  irc.run
rescue Interrupt
rescue Exception => oops
  puts oops.message
  print oops.backtrace.join("\n")
  retry
end

