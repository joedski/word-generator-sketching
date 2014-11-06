fs = require 'fs'

exports.digestFile = ( filePath, digesterModule, andThen ) ->
	fs.readFile filePath, { encoding: 'utf8' }, digestReadFileWithDigester( digesterModule, andThen )

digestReadFileWithDigester = ( digesterModule, andThen ) ->
	( error, data ) ->
		if error
			console.error "Received error trying to open corpus text."
			console.error error
			console.error "Returning empty array"
			# return []
			andThen error, []
		else
			andThen null, digesterModule.digest data

exports.writeDatabase = ( dbPath, rules, andThen ) ->
	rulesDB = { rules: rules }

	fs.writeFile dbPath, JSON.stringify( rulesDB ), { encoding: 'utf8' }, ( error ) ->
		if error
			console.error "Error trying to write database to '#{ dbPath }'."
			console.error error

		andThen error

exports.readDatabase = ( dbPath, digesterModule, andThen ) ->
	fs.readFile dbPath, { encoding: 'utf8' }, parseDatabaseWithDigester( digesterModule, andThen )

parseDatabaseWithDigester = ( digesterModule, andThen ) ->
	( error, dbData ) ->
		if error
			console.error "Error trying to read database."
			console.error error

			andThen error, null
		else
			andThen null, JSON.parse dbData, ( key, value ) ->
				if key is 'rules' and !isNaN( value.length )
					(digesterModule.Rule.fromJSON ruleJSON for ruleJSON in value)
				else
					value
