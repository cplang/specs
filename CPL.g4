grammar CPL;

/*
 * The grammar rules for CPL language.
 * 
 * 'v' is the root of the language, which stands for validation.
 * 'vline' is a one-liner validation.
 *
 */

v: (l+=vline)* EOF
	;

vline: non_v 				# NonVLine
	| predicate				# PredicateVLine
	;

non_v: cmd
	| pred_def
	;

cmd: LOAD kind=StringLiteral loc=StringLiteral								# CmdLoadSetting
	| LOADA kind=StringLiteral loc=StringLiteral							# CmdLoadASetting
	| GET qid																# CmdGetConf
	| INCLUDE file=StringLiteral											# CmdIncludeFile
	;

pred_def: 'let' ID ':=' constraint
	;

predicate: domains=expression_list '<-' cv=predicate			# PredicateDomainLeft
	| cv=predicate '->' domains=expression_list					# PredicateDomainRight
	| conditional												# PredicateConditional
	| constraint												# PredicateOnlyConstraint
	| ns=namespace												# PredicateNamespace
	| cp=compartment											# PredicateCompartment
	;

namespace: SCOPE ks=keyspaces sb=suite_block
	;

compartment: COMPART ks=keyspaces sb=suite_block
	;

conditional: IF LPAR cond=predicate RPAR i=suite				# ConditionalIfV
	| IF LPAR cond=predicate RPAR i=suite ELSE e=suite			# ConditionalIfElseV
	;

suite: predicate												# SuiteSingle
	| suite_block												# SuiteWithBlock
	;

suite_block: LBBRA (cs+=predicate)+ RBBRA
	;

constraint : simple_constraint				# ConstraintSimple
	;

simple_constraint :	p=small_constraint								# SimpleSmall
	| lhs=simple_constraint o=(AND | OR) rhs=small_constraint		# SimpleAndOr
	;

small_constraint: p=constraint_term									# SmallTerm
	| '~' p=constraint_term											# SmallNegate
	| '-]' p=constraint_term										# SmallAny
	| '-]!' p=constraint_term										# SmallUniqueExits
	;

constraint_term: LPAR p=constraint RPAR										# SmallSimple
	| p=constraint_primitive												# SmallPrimitive
	;

constraint_primitive
	: type													# ConstraintType
	| i=in													# ConstraintIn
	| LEN rel expression									# ConstraintLen
	| expression											# ConstraintExpression
	| '@'ID													# ConstraintRef
	| NONEMPTY												# ConstraintNonEmpty
	| CONSISTENT											# ConstraintConsistency
	| EXISTS												# ConstraintExists
	| o=(SORTED | ASC | DESC)								# ConstraintSort	
	| UNIQUE												# ConstraintUnique
	| UNIQUE param											# ConstraintUniqueParam
	| MATCH param											# ConstraintMatch
	| EQUALS param											# ConstraintEquals
	;

idlist : l=idlist ',' '$'? r=qid
	| '$'? qid
	;

qid: keyspace
	;

keyspaces: keyspaces ',' keyspace
	| keyspace
	;

keyspace:	keyspace '.' wid
	| keyspace '::' '$'? wid
	| keyspace '[' IntegerLiteral ']'
	| keyspace '[' '$'? wid ']'
	| wid
	;

wid : ID
	| WID
	| '*'
	;

type : T_VAR							# TypeVar
	| T_INT								# TypeInt					
	| T_FLOAT							# TypeFloat
	| T_BOOL							# TypeBool
	| T_STRING							# TypeString
	| T_CHAR							# TypeChar
	| T_IP								# TypeIP
	| T_URL								# TypeURL
	| T_HOST							# TypeHost
	| T_CIDR							# TypeCIDR
	| T_PATH							# TypePath
	| T_ARGS							# TypeARGS
	| T_TIME							# TypeTime
	| T_DATE							# TypeDate
	| T_ENUM							# TypeEnumEmpty
	| T_ENUM  e=in						# TypeEnum
	| T_LIST '<' t=type '>'				# TypeList
	;

param : LPAR lst=expression_list RPAR
	;

in  : LBBRA lst=expression_list RBBRA
	;

expression_list : l=expression_list ',' r=expression	# ListExprs
	| expression										# ListSingleExpr
	;

literal : IntegerLiteral						# ConstInt 
	| FloatingPointLiteral						# ConstFloat
	| BooleanLiteral							# ConstBool
	| str=(StringLiteral | CharacterLiteral)	# ConstString
	| IPLiteral									# ConstIP
	| CIDRLiteral								# ConstCIDR
	;

unaryExpression : '$'? qid							# UnaryVar
	| '$' f=qid LPAR args=expression_list RPAR		# UnaryCall
	| literal										# UnaryConst
	| LPAR expression RPAR							# UnaryExpr
	;

multExpression : unaryExpression						# MultUnary
	| l=multExpression MULT r=unaryExpression			# MultMult
	| l=multExpression DIV r=unaryExpression			# MultDiv
	;

addExpression : multExpression							# AddMult
	| l=addExpression ADD r=multExpression				# AddAdd
	| l=addExpression MINUS r=multExpression			# AddMinus
	;

relationalExpression : addExpression					# RelationAdd
	| l=relationalExpression rel r=addExpression		# RelaitionComp
	;

rangeExpression : e=relationalExpression								# RangeRelation
	| LSBRA l=relationalExpression ',' r=relationalExpression RSBRA		# RangePair
	| LSBRA l=relationalExpression RSBRA								# RangeSingle
	;

expression : e=rangeExpression							# ExprRange
	| '(::' ks=keyspace e=rangeExpression ')'			# ExprComparted
	;

rel	: op=(LE | GE | EQ | NEQ | LT | GT)
	;

/*
 * Lexer Rules
 */

T_VAR: 'var';
T_INT: 'int';
T_FLOAT: 'float';
T_BOOL: 'bool';
T_STRING: 'string';
T_CHAR: 'char';
T_IP: 'ip';
T_PATH: 'path';
T_URL: 'url';
T_HOST: 'host';
T_CIDR: 'cidr';
T_ARGS: 'args';
T_TIME: 'time';
T_DATE: 'date';
T_LIST: 'list';
T_ENUM: 'enum';

IF: 'if';
ELSE: 'else';

// commands
GET: ('get' | 'GET');
LOAD: ('load' | 'LOAD');
LOADA: ('loada' | 'LOADA');
INCLUDE: ('include' | 'INCLUDE');


// constraint primitives
IN: ('in' | 'IN');
LEN: ('len' | 'LEN');
SCOPE: ('scope' | 'SCOPE');
EXISTS: ('exists' | 'EXISTS');
UNIQUE: ('unique' | 'UNIQUE');
MATCH: ('match' | 'MATCH');
CONSISTENT: ('consistent' | 'CONSISTENT');
NONEMPTY: ('nonempty' | 'NONEMPTY');
EQUALS: ('equals' | 'EQUALS');
SORTED: ('sorted' | 'SORTED');
ASC: ('asc' | 'ASC');
DESC: ('desc' | 'DESC');
COMPART: ('compartment' | 'COMPARTMENT');

// int
IntegerLiteral
	: DecimalInterger
	| DecimalOctet
	;

// decimal octet
DecimalOctet
	: Digit
	| NonZeroDigit Digit
	| '1' Digit Digit
	| '2' [0-4] Digit
	| '25' [0-5]
	;

fragment DecimalInterger
	: '0'
	| NonZeroDigit Digits
	;

fragment Digits: Digit+;

fragment Digit
	: '0'
	| NonZeroDigit
	;

fragment NonZeroDigit: [1-9];

fragment PrefixSize: Digit
	| [0-2] Digit
	| '3' [0-2]
	;

// float
FloatingPointLiteral: Digits '.' Digits;

fragment True: [tT][rR][uU][eE];
fragment False: [fF][aA][lL][sS][eE];
fragment Yes: [yY][eE][sS];
fragment No: [nN][oO];
fragment On: [oO][nN];
fragment Off: [oO][fF][fF];

// boolean
BooleanLiteral: True
	| False
	| Yes
	| No
	| On
	| Off
	;

fragment EscapeChar
	: '\\' .
	;

fragment SPACES
	: [ \t]+
	;

// char
CharacterLiteral: '\'' (EscapeChar | ~['\\\r\n]) '\'';

// string
StringLiteral: '\'' (EscapeChar | ~['\\\r\n])* '\''
	| '"' (EscapeChar | ~["\\\r\n])* '"'
	;

// ip
IPLiteral: DecimalOctet '.' DecimalOctet '.' DecimalOctet '.' DecimalOctet
	;

CIDRLiteral: IPLiteral '/' PrefixSize
	;

COMMA: ';';

LE: '<=';
GE: '>=';
EQ: '==';
NEQ: '!=';
LT: '<';
GT: '>';
ADD: '+';
MINUS: '-';
MULT: '*';
DIV: '/';

AND: '&';
OR: '|';

LPAR: '(';
RPAR: ')';

LSBRA: '[';
RSBRA: ']';

LBBRA: '{';
RBBRA: '}';

ID: [_a-zA-Z][_a-zA-Z0-9]*;
WID: [*_a-zA-Z][*_a-zA-Z0-9]*;

BlockComment :   '/*' .*? '*/' -> skip;

LineComment :   '//' ~[\r\n]* -> skip;

WS: (' '|'\n' | '\r'|'\t'|'\f' )+ -> skip;