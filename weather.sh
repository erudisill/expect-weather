#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

package require Expect

package require http


# weather - Expect script to get the weather (courtesy University of Michigan)
# Don Libes
# Version 1.10

# local weather is retrieved if no argument
# argument is the National Weather Service designation for an area
# I.e., WBC = Washington DC (oh yeah, that's obvious)

# Notes from Larry Virden <lvirden@yahoo.com> about the new host,
# rainmaker.wunderground.com: "[the] new site requires the
# machine doing the request be located in reverse dns lookup
# or it refuses to provide data."  This appears to be a blind error
# condition on the part of rainmaker.

exp_version -exit 5.0

if {$argc>0} {set code $argv} else {set code "WBC"}

proc timedout {} {
	send_user "Weather server timed out.  Try again later when weather server is not so busy.\n"
	exit 1
}

set timeout 60

set env(TERM) vt100	;# actual value doesn't matter, just has to be set

spawn telnet rainmaker.wunderground.com 3000
while {1} {
	expect timeout {
		send_user "failed to contact weather server\n"
		exit
	} "Press Return to continue*" {
               # this prompt used sometimes, eg, upon opening connection
               send "\r"
	} "Press Return for menu*" {
               # this prompt used sometimes, eg, upon opening connection
               send "\r"
	} "M to display main menu*" {
		# sometimes ask this if there is a weather watch in effect
		send "M\r"
	} "Change scrolling to screen*Selection:" {
		break
	} eof {
		send_user "failed to telnet to weather server\n"
		exit
	}
}
send "C\r"
expect timeout timedout "Selection:"
send "4\r"
expect timeout timedout "Selection:"
send "1\r"
expect timeout timedout "Selection:"
send "1\r"
expect timeout timedout "city code:"
send "$code\r"
expect $code		;# discard this


set temp "0"
set humidity "0"
set wind "0"
set pressure "0"
set weather "0"

#exp_internal 1

#  Weather Conditions at 03:52 PM EDT on 21 Apr 2014 for Washington, DC.
#  Temp(F)    Humidity(%)    Wind(mph)    Pressure(in)    Weather
#  ========================================================================
#    69          24%         NORTH at 0       30.01      Scattered Clouds
#
# =======\s+			Skip last = and spaces leading up to temp
# (\d+)					One or more digits for temp
# \s+					Skip one or more spaces
# (\d+%)				One or more digits followed by a % for humitidy
# \s+					Skip one or more spaces
# ([\w\s]+?)			One or more more alphanumeric or space characters for wind
# \s{3,}				Skip 3 or more spaces .. Since wind could have spaces in the data
# ([\d\.]+)				One or more digits or decimals for pressure
# \s+					Skip one or more spaces
# (\w[^\r\n]+)			Start with an alphanumeric then one or more until \r or \n for weather.

while {1} {
	expect timeout {
		timeout
	} -re {=======\s+(\d+)\s+(\d+%)\s+([\w\s]+?)\s{3,}([\d\.]+)\s+(\w[^\r\n]+)} {
		set temp $expect_out(1,string)
		set humidity $expect_out(2,string)
		set wind $expect_out(3,string)
		set pressure $expect_out(4,string)
		set weather $expect_out(5,string)
		break
	}
}
#exp_internal 0


while {1} {
	expect timeout {
		timedout
	} "Press Return to continue*:*" {
		send "\r"
	} "Press Return to display statement, M for menu:*" {
		send "\r"
	} -re "(.*)CITY FORECAST MENU.*Selection:" {
		break
	} 
}

send "X\r"
expect

puts ""
puts ""
puts "**** RESULTS ****"
puts "temp     : $temp"
puts "humidity : $humidity"
puts "wind     : $wind"
puts "pressure : $pressure"
puts "weather  : $weather"
				
set queryString [http::formatQuery 	"action" "weather"		\
									"temp" "$temp" 			\
									"humidity" "$humidity"	\
									"wind" "$wind"			\
									"pressure" "$pressure"	\
									"weather" "$weather"]

http::geturl http://localhost:1337/?$queryString


