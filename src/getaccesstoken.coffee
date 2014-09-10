###
	Copyright 2012-2014 David Pearson.

	BSD License.
###

http = require "http"
open = require "open"
querystring = require "querystring"
request = require "request"
url = require "url"

reqTokenURL = "https://api.twitter.com/oauth/request_token"
accessTokenURL = "https://api.twitter.com/oauth/access_token"
authURL = "https://api.twitter.com/oauth/authorize"

callback = "http://localhost:1234/"

if process.argv.length < 4
	console.log "USAGE: node getaccesstoken.js CONSUMER_KEY CONSUMER_SECRET"
	return

consumerKey = process.argv[2]
consumerSecret = process.argv[3]

oauthToken = ""
oauthTokenSecret = ""

serverHasResponded = false
server = null

opts =
	url	 : reqTokenURL
	oauth :
		"oauth_callback"  : callback
		#"callback"        : callback
		"consumer_key"    : consumerKey
		"consumer_secret" : consumerSecret

request.post opts, (e, res, retBody) ->
	body = querystring.parse retBody

	oauthToken = body["oauth_token"]
	oauthTokenSecret = body["oauth_token_secret"]

	open "#{authURL}?oauth_token=#{oauthToken}"

	server = http.createServer responseListener
		.listen 1234

responseListener = (req, response) ->
	if serverHasResponded
		return true

	serverHasResponded = true

	query = url.parse req.url
		.query
	qs = querystring.parse query

	oauth =
		"consumer_key"		: consumerKey
		"consumer_secret" : consumerSecret
		"token"					 : oauthToken
		"token_secret"		: oauthTokenSecret
		"verifier"				: qs["oauth_verifier"]

	opts =
		url	 : accessTokenURL
		oauth : oauth

	request.post opts, (e, res, retBody) ->
		body = querystring.parse retBody

		response.writeHead 200, {"Content-Type":"text/html"}
		response.end "<head><title>Oauth Information</title></head><body>\
			Consumer Key: #{consumerKey}<br/>Consumer Secret: #{consumerSecret}\
			<br/><br/>Access Token: #{body["oauth_token"]}<br/>Access Token Secret: \
			#{body["oauth_token_secret"]}</body>"
		server.close()