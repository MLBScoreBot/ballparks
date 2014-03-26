###
	Copyright 2013-2014 David Pearson.
	All rights reserved.
###

fs = require "fs"
http = require "http"

additionalStadiums = ["/wiki/Sydney_Cricket_Ground"]

connect = (host, path, cb) ->
	opts =
		method  : "GET"
		host    : host
		path    : path
		headers :
			"User-Agent" : "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US)
							AppleWebKit/525.13 (KHTML, like Gecko) Chrome/0.A.B.C
							Safari/525.13"

	req = http.request opts, (res) ->
		body = ""

		res.on "data", (chunk) ->
			body += chunk

		res.on "end", ->
			cb body, path

	req.end()

stadiums = {}

done = 0
num = 0

processStadium = (url) ->
	connect "en.wikipedia.org", url, (body, path) ->
		name = path.split("/wiki/")[1]
			.replace /_/g, " "
			.replace /%26/g, "&"
			.replace /\s*\([A-z0-9\s]*\)/g, ""
		console.log name

		coords = body.toString()
			.split("<span class=\"geo\">")[1]
			.split("</span>")[0]
			.split "; "

		parts = body.toString()
			.replace /\n/g, ""
			.split "</a> (<a href=\"/wiki/Major_League_Baseball\" title=\"Major League Baseball\">MLB</a>)"
		if parts.length is 1
			parts = parts[0].split "</a> (MLB)"

		team =
			if parts.length > 1
				parts[0].substring(parts[0].lastIndexOf(">") + 1)
			else
				""

		stadiums[name] =
			lat  : parseFloat coords[0]
			long : parseFloat coords[1]
			team : team

		done += 1

		if done is num
			teams = {}
			for s of stadiums
				t = stadiums[s].team
				if t isnt ""
					teams[t] =
						ballpark : s
						lat   : stadiums[s].lat
						long  : stadiums[s].long

			fs.writeFileSync "ballparks.json", JSON.stringify(stadiums)
			fs.writeFileSync "teams.json", JSON.stringify(teams)

connect "en.wikipedia.org", "/wiki/List_of_Major_League_Baseball_stadiums", (body, path) ->
	lines = body.toString()
		.replace /\n/g, ""
		.split("Ballpark typology")[1]
		.split "<a href=\""

	i = 2

	while i < lines.length
		url = lines[i].split("\"")[0]

		if url.indexOf("Portal:") < 0
			num += 1
			processStadium url

		i += 1

		while i < lines.length
			url = lines[i].split("\"")[0]
			i += 1
			if url.indexOf("File:") >= 0
				break

	for url in additionalStadiums
		num += 1
		processStadium url