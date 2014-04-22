var http = require('http');
var url = require('url');
var querystring = require('querystring');
var fs = require('fs');

http.createServer(function(req, res) {
    var query = url.parse(req.url).query;
    var params = querystring.parse(query);

    if (params && params.action) {
    	if (params.action === "weather") {
			params.timestamp = new Date();
			fs.writeFile('./weather.json', JSON.stringify(params), function(err) {
				if (err) console.log('Error writing weather.json: ' + err);
				else console.log('Weather written to weather.json.');
			});
			res.writeHead(200, {
				'Content-Type': 'text/plain'
			});
			res.end();
        } else if (params.action === "get") {
			fs.readFile('./weather.json', function(err,data) {
				if (err) {
					console.log('Error reading weather file: ' + err);
					res.writeHead(500, 'Error reading weather file.', {
						'Content-Type': 'text/plain'
					});
					res.end();
				} else {
					console.log('Reading weather file.');
					res.writeHead(200, {
						'Content-Type': 'application/json'
					});
					res.end(data);
				}
			});
        } else {
        	console.log('Invalid action parameter.');
			res.writeHead(400, 'Invalid action parameter.', {
				'Content-Type': 'text/plain'
			});
			res.end();
        }        
    } else {
    	res.writeHead(200, 'tex/html');
    	var fileStream = fs.createReadStream('./index.html');
    	fileStream.pipe(res);
    }
}).listen(1338);

console.log('Server running on port 1338');
