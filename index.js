// index.js

CoffeeScript = require( 'coffee-script/register' );

Digester = require( './digester.flavored' );
FileDigester = require( './file-digester' );

var args = require( 'minimist' )( process.argv.slice( 2 ) );
var corpusText = args[ '_' ][ 0 ];
var shouldWriteDB = args[ 'd' ];

if( ! corpusText ) {
	console.log( "No corpus text provided." );
	process.exit( 0 );
}

FileDigester.digestFile( corpusText, Digester, doStuff );

// function logRules( error, ruleArray ) {
// 	ruleArray.forEach( function logSingleRule( rule, ruleIndex ) {
// 		var positionName =
// 			rule.wordInitial ? '(initial)' : rule.wordFinal ? '(final)' : '';
// 		console.log( "Rule:", rule.initial + '<' + rule.medial + '>' + rule.final, positionName );
// 	});
// }

function doStuff( error, ruleArray ) {
	if( error ) {
		console.error( "Error trying to do stuff!  Can't do stuff!" );
		console.error( error );
		return process.exit( 1 );
	}

	var dbName = corpusText.replace( /\.[^.]+$/, '' ) + '.json';

	if( shouldWriteDB ) {
		FileDigester.writeDatabase( dbName, ruleArray, andThenMakeWords );
	}
	else {
		andThenMakeWords();
	}

	function andThenMakeWords( error ) {
		if( error ) {
			console.error( "Error writing database at '" + dbName + "'." );
			console.error( error );
			return process.exit( 1 );
		}

		makeWords( ruleArray );
	}
}

function memoizeMap( fn ) {
	var memoKeys = [], memoValues = [];

	function mapValue( key ) {
		var mapIndex = memoKeys.indexOf( key );
		if( mapIndex < 0 ) return undefined;
		return memoValues[ mapIndex ];
	}

	return function memoizedMapFn( key ) {
		var value = mapValue( key );

		if( ! value ) {
			value = fn( key );
			memoKeys.push( key );
			memoValues.push( value );
		}

		return value;
	};
}

function makeWords( ruleArray ) {
	function sample( array ) {
		var index = Math.random() * array.length << 0;
		return array[ index ];
	}

	function isInitialRule( rule ) {
		return rule.wordInitial;
	}

	function isNotInitialRule( rule ) {
		return ! isInitialRule( rule );
	}

	function isFinalRule( rule ) {
		return rule.wordFinal;
	}
	
	var getRulesFollowing = memoizeMap( function getRulesFollowing( leadingRule ) {
		return ruleArray.filter( leadingRule.canLead.bind( leadingRule ) );
	});

	var initialRuleArray = ruleArray.filter( isInitialRule );
	var nonInitialRuleArray = ruleArray.filter( isNotInitialRule );
	var finalRuleArray = ruleArray.filter( isFinalRule );
	var wordCount = 10;
	var currentWord = 0;

	for( currentWord = 0; currentWord < wordCount; ++currentWord ) {
		console.log( makeSingleWord() );
	}

	function makeSingleWord() {
		var initialRule, lastRule;
		var word = '';
		var ruleCount = 1, ruleCountLimit = 5;
		var nonInitialRulesFollowingLastRuleArray;

		lastRule = sample( initialRuleArray );
		word = lastRule.toString();

		while( ! lastRule.wordFinal && ruleCount < ruleCountLimit - 1 ) {
			nonInitialRulesFollowingLastRuleArray = getRulesFollowing( lastRule );
			lastRule = sample( nonInitialRulesFollowingLastRuleArray );
			word = word + lastRule.toString();
			++ruleCount;
		}

		if( ! lastRule.wordFinal ) {
			nonInitialRulesFollowingLastRuleArray = getRulesFollowing( lastRule ).filter( isFinalRule );
			lastRule = sample( nonInitialRulesFollowingLastRuleArray );

			word = word + lastRule.toString();
		}

		return word;
	}
}
