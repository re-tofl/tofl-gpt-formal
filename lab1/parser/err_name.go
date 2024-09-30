package parser

const (
	parsePairError               = "in parse can't extract pair: %+v"
	parseRepresentationError     = "in parse can't parse to linear representation: %+v"
	basePairFail                 = "the regular expression pair is written out incorrectly."
	arrowError                   = "all pairs must look like ... -> ..."
	parseError                   = "can't parse string: %+v"
	stackSizeError               = "stack must contain one element, it contain %d"
	openBracketError             = "in case '(' with element %s error %+v\n"
	closeBracketStackLoopError   = "in case ')' in loop iterators %d element has error %+v\n"
	closeBracketStackConstrError = "in case ')' in pop constructor name has error %+v\n"
	closeBracketComposeError     = "in case ')' in compose form has error %+v\n"
	constructorTooMuchParams     = "in case ')' constructor has more than 2 elements\n"
	emptyVariable                = "one of variables is an empty"
	dimensionalNotEqual          = "dimensionality constructors '%s' isn`t equal. was: %d, given: %d"
)
