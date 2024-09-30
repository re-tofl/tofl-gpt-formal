package parser

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/VyacheslavIsWorkingNow/tfl/lab1/stack"
)

type Expression struct {
	EPs                       []ExpressionPair
	NameConstructorToConstant map[string]Constructor
	Variables                 map[string]struct{}
}

type ExpressionPair struct {
	Left  ConstantAndVariables
	Right ConstantAndVariables
}

type VarToConstCombination map[string][]string

type ConstantAndVariables struct {
	Name string
	cAv  VarToConstCombination
}

type Constructor struct {
	Dimensionality int
	Constants      []string
}

func InitExpression() *Expression {
	return &Expression{
		EPs:                       make([]ExpressionPair, 0),
		NameConstructorToConstant: make(map[string]Constructor),
		Variables:                 make(map[string]struct{}),
	}
}

func Parse(input string) (string, error) {
	expr := InitExpression()

	if err := expr.ExtractPair(input); err != nil {
		return "", fmt.Errorf(parsePairError, err)
	}

	if err := expr.ParseExpressionsToLinearRepresentation(); err != nil {
		return "", fmt.Errorf(parseRepresentationError, err)
	}

	if err := expr.BringingSuchForLinearForms(); err != nil {
		return "", fmt.Errorf("parse error in bringing such %+v", err)
	}

	report, err := expr.GenerateSMT2()
	if err != nil {
		return "", fmt.Errorf("parse error in generate smt2 %+v", err)
	}

	return report, nil
}

func (e *Expression) ExtractPair(input string) error {

	fmt.Printf("start parsing\n")

	inputPairs := strings.Split(input, "\n")

	re := regexp.MustCompile(`([^->]+)->([^->]+)`)

	for _, ip := range inputPairs {
		match := re.FindStringSubmatch(ip)
		if len(match) == 3 {
			left := strings.TrimSpace(match[1])
			right := strings.TrimSpace(match[2])
			pair := ExpressionPair{
				Left:  ConstantAndVariables{Name: left},
				Right: ConstantAndVariables{Name: right},
			}
			e.EPs = append(e.EPs, pair)
		} else {
			return fmt.Errorf(basePairFail + "\n" + arrowError)
		}
	}

	fmt.Printf("after spliting into pairs:\n%s", e.ToStringLinearExpression())

	return nil
}

func (e *Expression) ToStringLinearExpression() string {
	linear := ""
	for i, expr := range e.EPs {
		linear += fmt.Sprintf("%d:\nleft: %s\nright: %s\n", i, expr.Left.Name, expr.Right.Name)
	}
	linear += "\n"
	return linear
}

func (e *Expression) ToStringConstructions() string {
	constr := ""
	for name, constant := range e.NameConstructorToConstant {
		constr += fmt.Sprintf("name: %s, constants: %+v\n", name, constant)
	}
	constr += "\n"
	return constr
}

func (e *Expression) ToStringVariables() string {
	variables := ""
	for v := range e.Variables {
		variables += fmt.Sprintf(", %s", v)
	}
	variables += "\n"
	return variables[2:]
}

func (e *Expression) ParseExpressionsToLinearRepresentation() error {

	linearPair := make([]ExpressionPair, len(e.EPs))
	for i, p := range e.EPs {
		var err error
		linearPair[i].Left.Name, err = e.parseOneFunctionToLinearRepresentation(p.Left.Name)
		if err != nil {
			return fmt.Errorf(parseError, err)
		}
		linearPair[i].Right.Name, err = e.parseOneFunctionToLinearRepresentation(p.Right.Name)
		if err != nil {
			return fmt.Errorf(parseError, err)
		}
	}

	e.EPs = linearPair

	fmt.Printf("after parsing into linear expression\n")
	fmt.Printf("linear expression: \n%s", e.ToStringLinearExpression())
	fmt.Printf("constructor and constants:\n%s", e.ToStringConstructions())
	fmt.Printf("variables:\n%s", e.ToStringVariables())

	return nil
}

func (e *Expression) parseOneFunctionToLinearRepresentation(expr string) (string, error) {

	re := regexp.MustCompile(`[(),]|\w+`)

	// Разбил отдельно на имена конструкторов и переменных, скобки и запятые
	parts := re.FindAllString(expr, -1)

	stackExpr := stack.InitStackString()

	for _, p := range parts {
		switch p {
		case "(":
			if err := e.openBracketCase(stackExpr, p); err != nil {
				return "", err
			}
		case ")":
			if err := e.closeBracketCase(stackExpr); err != nil {
				return "", err
			}
		case ",":
			continue
		default:
			stackExpr.Push(p)
		}
	}

	if stackExpr.Size() != 1 {
		return "", fmt.Errorf(stackSizeError, stackExpr.Size())
	}

	return stackExpr.Pop()
}

func (e *Expression) openBracketCase(s *stack.Stack[string], p string) error {
	_, err := s.Back()
	if err != nil {
		return fmt.Errorf(openBracketError, p, err)
	}
	s.Push(p)

	return nil
}

func (e *Expression) closeBracketCase(s *stack.Stack[string]) error {

	curVariables := make([]string, 0)

	for countElem := 0; countElem < 3; countElem++ {
		curElem, err := s.Pop()
		if err != nil {
			return fmt.Errorf(closeBracketStackLoopError, countElem, err)
		}
		if curElem == "(" {
			constructor, cErr := s.Pop()
			if cErr != nil {
				return fmt.Errorf(closeBracketStackConstrError, cErr)
			}

			form, fErr := e.composeLinearForm(constructor, curVariables)
			if fErr != nil {
				return fmt.Errorf(closeBracketComposeError, fErr)
			}

			s.Push(form)
			return nil
		}
		curVariables = append(curVariables, curElem)
	}

	return fmt.Errorf(constructorTooMuchParams)
}

func (e *Expression) composeLinearForm(constructor string, curVariables []string) (string, error) {

	// работа с добавлением реальных переменных
	// использую грязный хак: у переменной по условию нет впереди себя открывающей скобки
	// если открывающая скобка есть - то это уже линейное выражение
	// соответственно проверяю на наличие скобки и кладу их в set (в Golang это мапа пустых структур)

	for _, cv := range curVariables {
		if len(cv) == 0 {
			return "", fmt.Errorf(emptyVariable)
		}
		if cv[0] != '(' {
			e.Variables[cv] = struct{}{}
		}
	}

	// если конструктор уже лежал в мапе, то я сравниваю размерности
	// если они совпадают, то константы уже заданы, иначе - создаю список констант и кладу их в мапу
	if _, ok := e.NameConstructorToConstant[constructor]; ok {

		if e.NameConstructorToConstant[constructor].Dimensionality != len(curVariables) {
			return "",
				fmt.Errorf(dimensionalNotEqual,
					constructor, e.NameConstructorToConstant[constructor].Dimensionality, len(curVariables),
				)
		}
	} else {
		e.NameConstructorToConstant[constructor] = Constructor{
			Dimensionality: len(curVariables),
			Constants:      generateConstants(constructor, len(curVariables)+1),
		}
	}

	return getLinearForm(e.NameConstructorToConstant[constructor], curVariables), nil
}

func generateConstants(constructName string, countVar int) []string {
	constants := make([]string, countVar)
	for i := 0; i < countVar; i++ {
		constants[i] = fmt.Sprintf("%s_%d", constructName, i)
	}
	return constants
}

func getLinearForm(c Constructor, variable []string) string {

	var linearForm string

	switch c.Dimensionality {
	case 0:
		// const_0
		linearForm = fmt.Sprintf("(%s)", c.Constants[0])
	case 1:
		// x * const_1 + const_0
		linearForm = fmt.Sprintf("(%s * %s + %s)", variable[0], c.Constants[1], c.Constants[0])
	case 2:
		// y * const_2 + x * const_1 + const_0
		linearForm = fmt.Sprintf(
			"(%s * %s + %s * %s + %s)", variable[1], c.Constants[2], variable[0], c.Constants[1], c.Constants[0])
	}

	return linearForm
}

func (e *Expression) ToStringVarToConstCombination() string {
	linear := ""
	for i, expr := range e.EPs {
		linear += fmt.Sprintf("%d:\nleft: %+v\nright: %+v\n", i, expr.Left.cAv, expr.Right.cAv)
	}
	linear += "\n"
	return linear
}

func (e *Expression) BringingSuchForLinearForms() error {

	for i, p := range e.EPs {
		var err error
		e.EPs[i].Left.cAv, err = e.BringingLinearForm(p.Left.Name)
		e.EPs[i].Right.cAv, err = e.BringingLinearForm(p.Right.Name)
		if err != nil {
			return fmt.Errorf(parseError, err)
		}
	}

	fmt.Println("after similar ones:\n", e.ToStringVarToConstCombination())

	return nil
}

func (e *Expression) BringingLinearForm(expr string) (VarToConstCombination, error) {

	linearFormWithoutBrackets, wbErr := e.openBracketsMultiplication(expr)
	if wbErr != nil {
		return make(VarToConstCombination, 0), fmt.Errorf("can't open multiplicative brackets, %w", wbErr)
	}

	fmt.Printf("after open multiplicativity:\n%+v\n", linearFormWithoutBrackets)

	ansVarCombination, sovErr := e.similarOnesForVariable(linearFormWithoutBrackets)
	if sovErr != nil {
		return make(VarToConstCombination, 0), fmt.Errorf("can't open multiplicative brackets, %w", sovErr)
	}

	return ansVarCombination, nil
}

func (e *Expression) openBracketsMultiplication(expr string) ([]string, error) {

	// Убираем скобки слева и справа от выражения
	expr = expr[1 : len(expr)-1]

	re := regexp.MustCompile(`[()*+]|\w+`)

	// Разбил отдельно на имена переменных, константы, скобки, знаки сложения и умножения
	parts := re.FindAllString(expr, -1)

	stackExpr := stack.InitStackString()

	for i := 0; i < len(parts); i++ {
		switch parts[i] {
		case ")":
			// за закрывающей скобкой всегда следует знак умножения и то, на что мы умножаем
			if err := e.openDistributivity(stackExpr, parts[i+2]); err != nil {
				return make([]string, 0), fmt.Errorf("in case ')' was error: %w", err)
			}
			i += 2
		default:
			stackExpr.Push(parts[i])
		}
	}

	return stackExpr.GetBufferStack(), nil
}

func (e *Expression) openDistributivity(s *stack.Stack[string], multiplier string) (err error) {

	var elem string
	elements := make([]string, 0)

	for s.Size() > 0 {
		elem, err = s.Pop()
		if err != nil {
			return fmt.Errorf("in loop pop was %w", err)
		}

		if elem == "(" {
			break
		} else {
			elements = append(elements, elem)
		}
	}

	constructDistributivity(s, elements, multiplier)

	return nil
}

func constructDistributivity(s *stack.Stack[string], elements []string, multiplier string) {

	// развернул массив, чтобы было удобно работать с индексами
	reverseArray(elements)

	newElements := make([]string, 0)

	for _, elem := range elements {
		if elem == "+" {
			newElements = append(newElements, "*", multiplier, elem)
		} else {
			newElements = append(newElements, elem)
		}
	}

	newElements = append(newElements, "*", multiplier)

	for _, elem := range newElements {
		s.Push(elem)
	}
}

func reverseArray(a []string) {
	for i := 0; i < len(a)/2; i++ {
		a[i], a[len(a)-i-1] = a[len(a)-i-1], a[i]
	}
}

func (e *Expression) similarOnesForVariable(expr []string) (VarToConstCombination, error) {

	vcc := make(VarToConstCombination)

	curConstant := make([]string, 0)

	for _, elem := range expr {
		if elem == "+" {
			e.addConstantFromVariableName(curConstant, &vcc)
			curConstant = make([]string, 0)
		} else {
			curConstant = append(curConstant, elem)
		}
	}

	e.addConstantFromVariableName(curConstant, &vcc)

	return vcc, nil
}

func (e *Expression) addConstantFromVariableName(constants []string, vcc *VarToConstCombination) {
	// если первый символ переменная, а не свободный член
	if _, isVar := e.Variables[constants[0]]; isVar {
		// если до этого не было констант у переменной
		if _, inVcc := (*vcc)[constants[0]]; !inVcc {
			(*vcc)[constants[0]] = append(make([]string, 0), constants[2:]...)
			// уже были
		} else {
			(*vcc)[constants[0]] = append((*vcc)[constants[0]], "+")
			(*vcc)[constants[0]] = append((*vcc)[constants[0]], constants[2:]...)
		}
		// свободный член
	} else {
		// если до этого не было констант у переменной
		if _, inVcc := (*vcc)[" "]; !inVcc {
			(*vcc)[" "] = append(make([]string, 0), constants...)
			// уже были
		} else {
			(*vcc)[" "] = append((*vcc)[" "], "+")
			(*vcc)[" "] = append((*vcc)[" "], constants...)
		}
	}
}
