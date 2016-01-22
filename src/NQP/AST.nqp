
#sub qast-val($class-nm, $val) {
#  my $class := $class-nm eq 'IVal' ??
#     QAST::IVal !! $class-nm eq 'SVal' ??
#        QAST::SVal !! $class-nm eq 'NVal' ?? QAST::NVal !! QAST::WVal ;
#  qast($class-nm, $class.new(:value($val), :named<value>));
#}

sub qast-val($class, $val) {  qast($class, $class.new(:value($val), :named<value>)) }
sub qast-ival($val) { qast-val(QAST::IVal, $val) }
sub qast-nval($val) { qast-val(QAST::NVal, $val) }
sub qast-sval($val) { qast-val(QAST::SVal, $val) }
sub qast-wval($val) { qast-val(QAST::WVal, $val) }


sub qast-aval($val) {
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



sub qast-spair($key, $value)          {  QAST::SVal.new(:named($key), :value(~$value))  }
sub qast-npair($key, $value)          {  QAST::NVal.new(:named($key), :value(+$value))  }
sub qast-ipair($key, $value)          {  QAST::IVal.new(:named($key), :value(+$value))  }

sub qpair-name($key, $value)           {  $value.named<name>;  $value                    }
sub qpair-op($key, $value)             {  $value.named<op>;    $value                    }
sub qpair-value($key, $value)          {  $value.named<value>; $value                    }
sub qast-pair($key, $value)           {  $value.named(~$key); $value                    }
sub qast-op($op, *@args, :$node)              {     qast('Op', qast-spair('op',   $op), |@args) }
sub qast-named-op($op, $nm, *@args, :$node)   {  qast-op($op,  qast-spair('name', $nm), |@args) }
sub qast($class, *@args, :$node) {
     $class := $*W.find_sym(['QAST', $class]) if nqp::isstr($class);
     QAST::Op.new( :op<callmethod>, :name<new>,
        QAST::WVal.new(:value($class )),
        |@args)
}

class AST::HL-Var-actions {
      method variable($/) {   make QAST::Var.new(:name(~$<variable>), :scope<lexical>);  }
}

class AST::SL-Var-actions {
     method variable($/) {  make qast('Var', qpair-name(~$<variable>), qpair('scope', 'lexical' )) }
}


grammar AST::Grammar is HLL::Grammar {
    rule TOP {  <.ws> <EXPR>   }
    token term:sym<number>  {  [$<min>='-']? <number=.LANG('MAIN', 'number')> }
    token term:sym<variable> { <variable>   }
    token quote:sym<dblq> { <?["]>   { say('dbl') }         <quote_EXPR: ':qq'> }
    token variable {  <LANG('MAIN', 'variable', :actions(0))> }
#    token quote_escape:sym<$>         {           <?[$]>      <?quotemod_check('S')> { say('hi')}
#    <var=.LANG('MAIN', 'variable', AST::SL-Var-Actions)> }
    token quote_escape:sym<\\$>       { '\\$'                 <?quotemod_check('s')> }
    token quote_escape:sym<\\\\$>     { '\\\\'    <?[$]>      <?quotemod_check('s')> <var=.LANG('MAIN', 'variable', AST::SL-Var-Actions)> }
    token quote_escape:sym<\\\\\\$>   { '\\\\\\$' <?[$]>      <?quotemod_check('S')> <var=.LANG('MAIN', 'variable', AST::HL-Var-Actions)> }

}

class AST::Actions is HLL::Actions {
    method TOP($/) {
        make $<EXPR>.ast;
    }
    method term:sym<number>($/) {
        my $is-num   := nqp::index(~$/, '.') >= 0;
        my $val      := $<min> ?? -$/ !! +$/;
        my &fun := $is-num ??  &qast-nval !! &qast-ival;
        make &fun($val);
   }
}
