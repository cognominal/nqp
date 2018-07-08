# routines to generate QAST code that generate QAST code

sub q-pair-name($val)    {  q-spair('name', $val)                       }
sub q-pair-named($val)   {  q-spair('named', $val)                      }
sub q-pair-value($val)   {  q-spair('value', $val)                      }
sub q-spair($key, $val)  {  QAST::SVal.new(:named($key), :value(~$val))  }
sub q-npair($key, $val)  {  QAST::NVal.new(:named($key), :value(+$val))  }
sub q-ipair($key, $val)  {  QAST::IVal.new(:named($key), :value(+$val))  }
sub qq-val($class, $val) {  qq($class, $class.new(:value($val), :named<value>)) }
sub qq-ival($val) { qq-val(QAST::IVal, +$val) }
sub qq-nval($val) { qq-val(QAST::NVal, +$val) }
sub qq-sval($val) { qq-val(QAST::SVal, ~$val) }
sub qq-op($op,            *@args, :$node) { qq('Op',    q-spair('op',   $op), |@args) }
sub qq-named-op($op, $nm, *@args, :$node) { qq-op($op,  q-spair('name', $nm), |@args) }
sub q-w() { q-var('$*W')  }
sub q-var($nm, :$scope = 'var', :$decl) {  QAST::Var.new(:name($nm), :scope($scope))  }



sub qq($class, *@args, :$node) {
    $class := ~$class if $class ~~ NQPMatch;
    if nqp::isstr($class) {
        $class := $*W.find_sym(['QAST', $class]);
        nqp::die("can't find QAST::$class") unless nqp::istype($class, QAST::Node);
    } elsif !nqp::istype($class, QAST::Node) {
        nqp::die("\$class of unexpected type {$class.HOW.name($class)}" )
    }
    QAST::Op.new( :op<callmethod>, :name<new>, QAST::WVal.new(:value($class )), |@args)
}

# for debug sake
sub what($v) { $v.HOW.name($v) }
sub swhat($v, $s = '') { print("$s : ") if $s; say(what($v)) }
sub ad($ast, $t?) { say(($t ?? "$t" !! '') ~ $ast.dump); $ast }

# the categorization of classes derived from QAST::Node in leaves and not leaves is tentative
my @nodes;
my %leaves;
my @leaves := < IVal NVal SVal Var VarWithFallBack WVal VM SpecialArgs CompileTimeValue
                ParamTypeCheck NodeList Want >;
my @non-leaves := < Block Stmt Stmts Op NodeList Unquote InlinePlaceHolder Regex >;
nqp::push(@nodes, $_)       for @leaves;
nqp::push(@nodes, $_)       for @non-leaves;
nqp::bindkey(%leaves, $_, 1) for @leaves;


my %methodop       := nqp::hash('prec', 'y=', 'assoc', 'unary');
my %symbolic_unary := nqp::hash('prec', 'v=', 'assoc', 'unary');
my %comma          := nqp::hash('prec', 'g=', 'assoc', 'list', 'nextterm', 'nulltermish');



role AST::Grammar-Common {
    token value   { <number> } # | <str >                                                         }
    token name    { <.LANG('MAIN', 'name')>                                                       }

    token args    { '(' ~ ')' <arglist>       | <arglist>                                         }
    token arglist {  <.ws>  [   <EXPR('f=')>  | <?>        ]                                      }
    proto token terminator { <...> }
    token terminator:sym<;> { <?[;]> }
    token terminator:sym<}> { <?[}]> }
}

grammar AST::Grammar is HLL::Grammar does AST::Grammar-Common {
      rule TOP                  { <.ws> <EXPR>                                                      }
      rule term:sym<block>      {  '{' ~ '}'  <EXPR>                                                }
      rule term:sym<stmts>      { '-{' ~ '}'  <EXPR>                                                }
      rule term:sym<parens>     {  '(' ~ ')'  <EXPR>                                                }
      rule term:sym<splice>     { '{{' ~ '}}' <nqp-expr>                                            }
      token term:sym<value>     { <value>                                                           }
      token term:sym<var>       { <nqp-var=.LANG('MAIN', 'variable')>                               }
      token number              { [$<prefix>='+']? [$<min>='-']? <num=.LANG('MAIN', 'number')>      }
      token term:sym<op>        { <!before @nodes> <ident> <args>                                   }
      token term:sym<fun>       { '&'<ident>  <?before '(' > <args>                                 }
      token term:sym<+>         { <sym>  <nqp-expr>                                                 }
      token nqp-expr            { <nqp-expr=.LANG('MAIN', 'EXPR')>                                  }
      rule term:sym<short>      {
          [
              ||  WVal #  :!s
                  [ $<immediate-find-sym>='^' ]? <name>
              ||  $<node-name>=@leaves      <nqp-expr>
              ||  $<node-name>=@non-leaves  <EXPR>

          ]
      }
      token infix:sym<,>        { <sym>  <O(|%comma, :op<list>)>                                    }
}

class AST::Actions is HLL::Actions {
    method TOP($/)                 { make $<EXPR>.ast;                                            }
    method value($/)               { make $<str> ?? $<str>.ast !! $<number>.ast                   }
    method term:sym<value>($/)     { make $<value>.ast                                            }
    method number($/)              { make qq-ival($/);                                            }
    method term:sym<block>($/)     { make qq( QAST::Block, $<EXPR>.ast)                           }
    method term:sym<stmts>($/)     { make qq( QAST::Stmts, $<EXPR>.ast)                           }
    method term:sym<parens>($/)    { make $<EXPR>.ast                                             }
    method term:sym<splice>($/)    { make $<nqp-expr>.ast                                         }
    method term:sym<var>($/)       { make $<nqp-var>.ast                                          }
    method nqp-expr($/)            { make $<nqp-expr>.ast                                         }
    method term:sym<op>($/)        { make qq-op($<ident>,                         | $<args>.ast); }
    method term:sym<fun>($/)       { make qq-op('call', q-pair-name("&$<ident>"), | $<args>.ast); }

    method term:sym<+>($/)         {
        my $ast := $<nqp-expr>.ast;
        $ast.named('value');
        make qq(QAST::IVal, $ast)
    }


    method term:sym<short>($/)         {
        if $<name> {
            my $val := $<immediate-find-sym> ??
                QAST::WVal.new( :value( $*W.find_sym(nqp::split('::', ~$<name>)))) !!
                QAST::Op.new(:op<callmethod>, :name<find_sym>,
                     QAST::Var.new(:name<$*W>, :scope<contextual>),
                     QAST::Op.new(:op<split>, QAST::SVal.new(:value('::')), QAST::SVal.new(:value(~$<name>))));
                make qq(QAST::WVal, $val);
        } else  {
            my $ast;
            if $<nqp-expr> {
               $ast := $<nqp-expr>.ast;
                $ast.named('value');
            } else {
               $ast := $<EXPR>.ast;
            }
            $ast := qq(~$<node-name>, $ast);
            make $ast
        }
    }
    method args($/) { make $<arglist>.ast; }

    method arglist($/) {
        my @ast-args := [];
        if $<EXPR> {
            my $expr := $<EXPR>.ast;
            if nqp::istype($expr, QAST::Op) && $expr.name eq '&infix:<,>' && !$expr.named {
                for $expr.list { @ast-args.push($_); }
            }
            else { @ast-args.push($expr); }
        }
        make @ast-args;
    }
}



grammar ATM::Grammar is HLL::Grammar does AST::Grammar-Common {
}

class ATM::Actions is HLL::Actions {
}
