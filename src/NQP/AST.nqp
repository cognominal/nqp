=begin pod
A function with a name starting by C<qqq-> returns a QAST tree that generates
a QAST tree. Starting with C<qq> returns a QAST tree/node, with parameter $val
being a int, num or str.
Starting with C<q> returns other QAST tree/node, with parameter $val
being a QAST tree/node

=end pod

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
     $class := $*W.find_sym(['QAST', $class]) if nqp::isstr($class);
     QAST::Op.new( :op<callmethod>, :name<new>,
        QAST::WVal.new(:value($class )),
        |@args)
}

class AST::HL-Var-actions {
      method variable($/) {   make QAST::Var.new(:name(~$/), :scope<lexical>);  }
}

class AST::SL-Var-actions {
     method variable($/) {
        my $nm := QAST::Var.new(:name('$'~ $<desigilname>), :scope<lexical>);
        make qqq('Var', q-pair-name($nm), qq-spair('scope', 'lexical' ));
    }
}


grammar AST::Grammar is HLL::Grammar {
   INIT {
      NQP::Grammar.O(':prec<i=>, :assoc<right>', '%assignment');
   }


    rule TOP {  :my $*AST := 1; <.ws> <EXPR>                                                   }
    token circumfix:<{{ }}> { '{' [ <.ws> <EXPR>? ] '}'                        }
    token circumfix:<{ }>   { '{' [ <.ws> <EXPR>? ] '}'                        }
    token circumfix:<( )>   { '(' [ <.ws> <EXPR>? ] ')'                        }
    token infix:sym<:=>     { <sym>  <O('%assignment, :aop<bind>')>            }
    token term:sym<nqp::op> { $<op>=<[a..z]>+                                  }
    token arglist {  <.ws>  [ <EXPR('f=')> | <?>    ]                          }
    token args{ '(' <arglist> ')' | <arglist> | <?>                            }
    token term:sym<value> { <value>                                            }
    token value { <quote>| <number>                                            }
    token number  {  [$<min>='-']? <number=.LANG('MAIN', 'number')>            }
    rule  term:sym<decl-sl-var> { reg <sl-var>                                 }
    token term:sym<hl-var> { <hl-var>                                          }
    token term:sym<sl-var> { <sl-var>                                          }
    token hl-var {          <?before <sigil> > <var=.LANG('MAIN', 'variable', :actions(AST::HL-Var-actions))> }
    token sl-var { <sigil>  <?before <sigil> >  <var=.LANG('MAIN', 'variable', :actions(AST::SL-Var-actions))> }
    token colonpair {  <LANG('MAIN', 'colonpair')>                             }
    token sigil { <[$&%@]>                                                     }
    proto token quote { <...>                                                  }
# don't yet support all quotes not to clutter the grammar
    token quote:sym<apos> { <?[']>         <quote_EXPR: ':q'>                  }
    token quote:sym<dblq> { <?["]>         <quote_EXPR: ':qq'>                 }
    token quote_escape:sym<$>    {  <?[$]>              <?quotemod_check('s')>  <al-var>    }
    token quote_escape:sym<$$>   {  <?before '$$'> '$'  <?quotemod_check('S')>  <hl-var>    }

}

class AST::Actions is HLL::Actions {
    method TOP($/) {   make $<EXPR>.ast;                                       }
    method circumfix:<{{ }}>($/) {
         make qqq('Block', $<EXPR>.ast )
    }
    method circumfix:<{ }>($/) {  make qqq('Stmts', $<EXPR>.ast)               }
    method circumfix:<( )>($/) {  make $<EXPR>.ast                             }
    method term:sym<value>($/) {  make $<value>.ast                            }
    method value($/) {  make $<quote> ?? $<quote>.ast !! $<number>.ast         }
    method term:sym<hl-var>($/) {  make $<hl-var>.ast                          }
    method hl-var($/) { make $<var>.ast                                        }
    method term:sym<decl-sl-var>($/) {
        my $ast := $<sl-var>.ast;
        $ast.push(  qq-spair('decl', 'local'));
        $ast;
    }
    method term:sym<sl-var>($/) {  make $<sl-var>.ast                          }
    method sl-var($/) { make $<var>.ast                                        }
    method number($/) {
        my $is-num   := nqp::index(~$/, '.') >= 0;
        my $val      := $<min> ?? -$/ !! +$/;
        my &fun := $is-num ??  &qqq-nval !! &qqq-ival;
        make &fun($val);

    }
    method quote:sym<apos>($/) { make qqq-sval($<quote_EXPR>.ast.value)         }
}
