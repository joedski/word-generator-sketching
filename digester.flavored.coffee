###
Digester: Flavored Rule Generator
####

exports.digest = ( corpusText ) -> # :Array<Rule>
	digestWords breakIntoWords corpusText

breakIntoWords = ( corpusText ) -> # :Array<String>
	# Unfortunately, since orthography is arbitrary, there's no real uniform way to do this,
	# although with options this could cover the majority of orthographies.
	breakAtWordBoundaries normalizeText corpusText

digestWords = ( wordArray ) -> # :Array<Rule>
	ruleArrayArray = (digestSingleWord word for word in wordArray when word)
	ruleArray = []
	(ruleArray = ruleArray.concat nextRuleArray for nextRuleArray in ruleArrayArray)
	ruleArray

normalizeText = ( corpusText ) ->
	corpusText
		.toLowerCase()
		.replace( /\W+/g, ' ' )

breakAtWordBoundaries = ( text ) -> text.split /\W+/

digestSingleWord = ( word ) -> # :Rule
	# English isn't quite this simple since y is sometimes a vowel and sometimes a consonant,
	# but we'll roll with this for now.
	tokenizer = /[aeiouy]+|[^aeiouy]+/g # must be /g to avoid infinite loop.
	vowelTokenTest = /^[aeiouy]+$/
	nonvowelTokenTest = /^[^aeiouy]+$/

	isMedialToken = ( token ) -> !token or nonvowelTokenTest.test token

	match = null
	tokenArray = (match[ 0 ] while match = tokenizer.exec word)

	# rules always have consonants in the medial position.
	# A rule which starts a word with vowels is considered to have a null medial position.
	if ! isMedialToken tokenArray[ 0 ] then tokenArray.unshift ''
	# As is a rule which ends a word with vowels.
	if ! isMedialToken tokenArray[ tokenArray.length - 1 ] then tokenArray.push ''
	# Amy -> [ a, m, i ] -> [ '', a, m, i, '' ]

	for i in [ 0 ... tokenArray.length ] when i % 2 == 0
		new Rule( tokenArray[ i - 1 ] or '', tokenArray[ i ], tokenArray[ i + 1 ] or '' )

class Rule
	@fromJSON = ( jsonObject ) ->
		new Rule jsonObject.initial, jsonObject.medial, jsonObject.final

	wordInitial: false
	wordFinal: false
	initial: ''
	medial: ''
	final: ''

	constructor: ( @initial, @medial, @final ) ->
		@wordInitial = true if not @initial
		@wordFinal = true if not @final

	canFollow: ( beforeRule ) -> beforeRule.final == @initial
	canLead: ( afterRule ) -> afterRule.initial == @final

	# We can always omit @initial because,
	# when @wordInitial is true then @initial is '',
	# and when @wordInitial is not ture, then @initial == previous Rule's @final.
	toString: -> "#{ @medial }#{ @final }"
	toJSON: ->
		initial: @initial
		medial: @medial
		final: @final

exports.Rule = Rule
