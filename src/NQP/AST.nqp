=begin pod
A function with a name starting by C<qqq-> returns a QAST tree that generates
a QAST tree. Starting with C<qq> returns a QAST tree/node, with parameter $val
being a int, num or str.
Starting with C<q> returns other QAST tree/node, with parameter $val
being a QAST tree/node

=end pod

sub what($v) { $v.HOW.name($v) }
sub swhat($v, $s = '') { print("$s : ") if $s; say(what($v)) }


# probably useless
sub qqq-a-val($val) {
    if nqp::isint($val) {
     qast-ival($val)
    } elsif nqp::isstr($val) {
     qast-sval($val)
    } elsif nqp::isnum($val) {
     qast-nval($val)
    } else {
    qast-wval($val)
    }
 }
sub q-pair-name($val)     {  $val.named<name>;  $val  }
sub q-pair-op($val)       {  $val.named<op>;    $val  }
sub q-pair-value($val)    {  $val.named<value>; $val  }
sub q-pair($key, $val)    {  $val.named(~$key); $val  }

sub qq-pair-name($val)    {  qq-spair('name', $val)                       }
sub qq-pair-named($val)    {  qq-spair('named', $val)                       }
sub qq-pair-value($val)    {  qq-spair('value', $val)                     }
sub qq-spair($key, $val)  {  QAST::SVal.new(:named($key), :value(~$val))  }
sub qq-npair($key, $val)  {  QAST::NVal.new(:named($key), :value(+$val))  }
sub qq-ipair($key, $val)  {  QAST::IVal.new(:named($key), :value(+$val))  }

sub qqq-val($class, $val) {  qqq($class, $class.new(:value($val), :named<value>)) }
sub qqq-ival($val) { qqq-val(QAST::IVal, $val) }
sub qqq-nval($val) { qqq-val(QAST::NVal, $val) }
sub qqq-sval($val) { qqq-val(QAST::SVal, $val) }
sub qqq-wval($val) { qqq-val(QAST::WVal, $val) }
sub qqq-op($op, *@args, :$node)              {     qqq('Op', qq-spair('op',   $op), |@args) }
sub qqq-named-op($op, $nm, *@args, :$node)   {  qqq-op($op,  qq-spair('name', $nm), |@args) }
sub qqq($class, *@args, :$node) {
     $class := ~$class if $class ~~ NQPMatch;
     $class := $*W.find_sym(['QAST', $class]) if nqp::isstr($class);
     QAST::Op.new( :op<callmethod>, :name<new>,
        QAST::WVal.new(:value($class )),
        |@args)
}

class AST::HL-Var-actions {
    method variable($/) {
        make QAST::Var.new(:name(~$/), :scope<lexical>);
    }
}

class AST::SL-Var-actions {
     method variable($/) {
        my $nm := QAST::Var.new(:name('$'~ $<desigilname>), :scope<lexical>);
        make qqq('Var', q-pair-name($nm), qq-spair('scope', 'lexical' ));
    }
}


grammar AST::Grammar is HLL::Grammar {
    INIT {
       AST::Grammar.O(':prec<y=>, :assoc<unary>', '%methodop');
       AST::Grammar.O(':prec<g=>, :assoc<list>, :nextterm<nulltermish>',  '%comma');
       AST::Grammar.O(':prec<i=>, :assoc<right>', '%assignment');
       AST::Grammar.O(':prec<r=>, :assoc<left>',  '%concatenation');
    }


    rule TOP {  :my $*AST := 1; <.ws> <EXPR>                                    }
#    <statementlist>
    token term:sym<node> {
        $<name>=[ 'Rx-' $<type>=\w+ ['-' $<subtype>=\w+]? || <[A..Z]> \w+ ] <args>
    }
    proto token circumfix { <...> }
    token circumfix:sym<{{ }}> { '{{' [ <.ws> <EXPR>? ] '}}'                   }
    token circumfix:sym<{ }>   { '{' [ <.ws> <EXPR>? ] '}'                     }
    token circumfix:sym<( )>   { '(' [ <.ws> <EXPR>? ] ')'                     }
    token infix:sym<:=>   { <sym>  <O('%assignment, :aop<bind>')>              }
    token infix:sym<~>    { <sym>  <O('%concatenation, :aop<concat>')>         }
    token infix:sym<,>    { <sym>  <O('%comma, :aop<list>')>                   }
    token term:sym<nqp::op> { <!before <declarator> >> > $<op>=<[a..z]>+ <args> }
    token term:sym<fun>      { '&' <name> <args_>                               }
    token term:sym<value> { <value>                                            }
    token term:sym<colonpair> { <colonpair>                                    }
#    token postfix:sym<.>  { <dotty> <O('%methodop')> }
    token arglist {  <.ws>  [ <EXPR('f=')> | <?>    ]                          }
    token args  { '(' <arglist> ')' | <arglist> | <?>                          }
    token args_ { '(' <arglist> ')' | <arglist>                                }
    token value { <str> | <number>                                             }
    token str   {
        :my $*SL_VAR_OK := 1;
        [
        | '~' { $*SL_VAR_OK := 0 }  <quote>
        |                           <quote>
        ]
    }

    token number  {  [$<prefix>='+']? [$<min>='-']? <num=.LANG('MAIN', 'number')>  }
    token declarator { reg }
# :my *SCOPE := ~$<declarator>;
    rule  term:sym<decl-sl-var> { <declarator>    <.ws> <sl-var>               }
    token term:sym<hl-var> { <hl-var>                                          }
    token term:sym<sl-var> { <sl-var>                                          }
    token hl-var {          <?before <sigil> > <var=.LANG('MAIN', 'variable', :actions(AST::HL-Var-actions))> }
    token sl-var { <sigil>  <?before <sigil> >  <var=.LANG('MAIN', 'variable', :actions(AST::SL-Var-actions))> }
    token identifier { <.ident> [ <[\-']> <.ident> ]*                          }
    token name { <identifier> ['::'<identifier>]*                              }
    token colonpair {  <LANG('MAIN', 'colonpair')>                             }
    token sigil { <[$&%@]>                                                     }
    proto token quote { <...>                                                  }
# don't yet support all quotes not to clutter the grammar
    token quote:sym<apos> { <?[']>  <quote_EXPR: ':q'>                          }
    token quote:sym<dblq> { <?["]>  <quote_EXPR: $*SL_VAR_OK ?? ':qq' !! ':qq:S:A:H'> }
    token quote_escape:sym<$>    {  <?[$]>     <?quotemod_check('s')>  <hl-var>}
    token quote_escape:sym<$$>   {   <sl-var>  <?quotemod_check('S')>          }

    proto token terminator { <...> }
    token terminator:sym<;> { <?[;]> }
    token terminator:sym<}> { <?[}]> }
    token eat_terminator {
        || ';'
        || <?MARKED('endstmt')>
        || <?terminator>
        || $
    }
    rule statementlist {
        ''
        [
        | $
        | <?before <[\)\]\}]>>
        | [ <statement> <.eat_terminator> ]*
        ]
    }
    token statement($*LABEL = '') {
        <!before <[\])}]> | $ >
        [
        | <EXPR> <.ws>
            [
            || <?MARKED('endstmt')>
            || <statement_mod_cond> <statement_mod_loop>?
            ]
         ]
    }

    token dotty {
    [ '.' |  '->' ]
    [ <longname=deflongname>
#    | <?['"]> <quote>
#        [ <?[(]> || <.panic: "Quoted method name requires parenthesized arguments"> ]
    ]

    [  <args> | ':' \s <args=.arglist> ]?
}


}

class AST::Actions is HLL::Actions {
    method TOP($/) {   make $<EXPR>.ast;                                       }
    method circumfix:sym<{{ }}>($/) {

         make qqq('Block', $<EXPR>.ast )
    }
    method circumfix:sym<{ }>($/) {  make qqq('Stmts', $<EXPR>.ast)            }
    method circumfix:sym<( )>($/) {  make $<EXPR> ?? $<EXPR>.ast !! qqq-op('list')}
    method term:sym<node>($/) {
        my $ast;
        if $<name> {
            my $nm := ~$<name>;
            if $nm ~~ / ^ <[ISNW]> Val $ / {


            } elsif $nm eq 'Call' {

            }
            $ast := qqq($<name>);
            $ast.push: $<args>.ast;
        } else {
            $ast := qqq('Regex', qq-spair('rxtype', $<type>));
            $ast.push: qq-spair('subtype', $<subtype>)
        }
        make $ast;
    }

    sub op-args($/, $op, $pairs = [])  {
        my $args := $<args> // $<args_>;
        nqp::die('$<args> missing>') unless $args;
        my @pairs := $pairs ~~ NQPArray ?? $pairs !! [$pairs];
        $op := ~$op;
        my $ast;
        if $args<arglist> -> $l {
            $ast := $l.ast;
            if $ast[0].value =:= QAST::Op {
                # $<args>.ast generates a Op('call')
                # change in place to make it an Op($op)
                $ast[1] := qq-spair('op', $op);
                $ast;
            } else {
                $ast := qqq-op($op, $ast);
            }
            $ast.push: $_ for @pairs;
            $ast;
        } else {
            qqq-op($<op>)
        }

    }

    method term:sym<nqp::op>($/)  {  make op-args($/, $<op>); }
    method term:sym<fun>($/)  { make op-args($/, 'call', qq-pair-name('&' ~ $<name>)); }

    method postfix:sym<.>($/) {  make $<dotty>.ast }
    method dotty($/) {
        my $ast;
        my  $pair-name := qq-pair-name('&' ~ $<name>);
        if $<args><arglist> -> $l {
            $ast := $l.ast;
            if $ast[0].value =:= QAST::Op {
                my @from;
                @from.push: $pair-name;
                $ast[1] := qq-spair('op', 'call');
                nqp::splice($ast, @from, 2, 0);
                make $ast;
            } else {
                make qqq-op('call', $pair-name, $ast)
            }
        } else {
            make qqq-op('call', $pair-name)
        }


#        if $<quote> {
#            $ast.unshift($<quote>.ast);
#            $ast.op('callmethod');
#        }
#        else {
            $ast.name(~$<longname>);
            $ast.op('callmethod');
#        }
        make $ast;
        $/.prune;

    }


    method arglist($/) {  make $<EXPR> ?? $<EXPR>.ast !! qqq-op('list');       }
    method args($/) { make $<arglist>.ast;                                     }
    method term:sym<value>($/) {  make $<value>.ast                            }
    method term:sym<colonpair>($/) { make $<colonpair>.ast                     }
    method value($/) {  make $<str> ?? $<str>.ast !! $<number>.ast             }
    method term:sym<hl-var>($/) {  make $<hl-var>.ast                          }
    method hl-var($/) {
        make $<var>.ast
    }
    method term:sym<decl-sl-var>($/) {
        my $ast := $<sl-var>.ast;
        $ast.push(  qq-spair('decl', 'var'));
        make $ast;
    }
    method term:sym<sl-var>($/) {  make $<sl-var>.ast                          }
    method sl-var($/) { make $<var>.ast                                        }
    method number($/) {
        my $is-num   := nqp::index(~$<num>, '.') >= 0;
        my $val      := $<min> ?? -$<num> !! +$<num>;
        if $<prefix> {
            my $ast :=  ($is-num ?? QAST::NVal !! QAST::IVal).new(:value($val));
            make $ast;
        } else {
            my &fun := $is-num ??  &qqq-nval !! &qqq-ival;
            make &fun($val);
        }
    }
    method str($/) {  make $<quote>.ast }
    method quote_delimited($/) {
        my @parts;
        my $lastlit := '';
        for $<quote_atom> {
            my $ast := $_.ast;
            if !nqp::istype($ast, QAST::Node) {
                $lastlit := $lastlit ~ $ast;
            }
            elsif nqp::istype($ast, QAST::SVal) {
                $lastlit := $lastlit ~ $ast.value;
            }
# don't know how to handle the concat at compile time
             elsif $ast.ann('typed') {
                my $concat := QAST::Op.new(:op<concat>,
                    QAST::SVal.new(:value($lastlit)), $ast);
                $concat.named('value');
                my $n := qqq(QAST::SVal, $concat);
#                qq-pair-named('value'),
                say($n.dump);
                @parts.push: $n;
                $lastlit := '';
            }
            else {
                if $lastlit gt '' {
                    @parts.push(qqq-sval($lastlit));
                }
                @parts.push(nqp::istype($ast, QAST::Node)
                    ?? $ast
                    !! qqq-sval($ast));
                $lastlit := '';
            }
        }
        if $lastlit gt '' { @parts.push(qqq-sval($lastlit)); }
        my $ast := @parts ?? @parts.shift !! qqq-sval('');
        $ast := qqq-op('concat', $ast, @parts.shift) while @parts;
        say($ast.dump);
        make $ast;
    }
    method quote:sym<apos>($/) { make $<quote_EXPR>.ast                        }
    method quote_escape:sym<$>($/) {
        my $var := ~$<hl-var>;
        my %sym := $*W.find_sym($var, 0);
        nqp::die("no hl-var '$var'") unless %sym;
        my $type := %sym<type>;
        if $type =:= str || $type =:= int {
            my $ast := QAST::Var.new(:name($var), :scope<lexical>);
            $ast.annotate('typed', 1);
            make $ast;
        } else {
            make $<hl-var>.ast;
        }
    }
    method quote_escape:sym<$$>($/) {  make $<sl-var>.ast                      }
    method quote:sym<dblq>($/) { make $<quote_EXPR>.ast                        }

    ### incomplete
    method statement($/) {         make $<EXPR>.ast                            }
    method statementlist($/) {
      my $ast := qqq('Stmts'); # QAST::Stmts.new( :node($/) );
      $ast.push: $_.ast for $<EXPR>;
   }
}
