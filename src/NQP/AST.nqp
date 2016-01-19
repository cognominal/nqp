
sub qast-val($class-nm, $val) {
  my $class := $class-nm eq 'IVal' ??
     QAST::IVal !! $class-nm eq 'SVal' ??
        QAST::SVal !! $class-nm eq 'NVal' ?? QAST::NVal !! QAST::WVal ;
  qast($class-nm, $class.new(:value($val), :named<value>));
}


sub qast-spair($key, $value)          {  QAST::SVal.new(:named($key), :value(~$value))  }
sub qast-npair($key, $value)          {  QAST::NVal.new(:named($key), :value(+$value))  }
sub qast-ipair($key, $value)          {  QAST::IVal.new(:named($key), :value(+$value))  }
sub qast-pair($key, $value)           {  $value.named(~$key); $value                    }
sub qast-op($op, *@args, :$node)              {     qast('Op', qast-spair('op',   $op), |@args) }
sub qast-named-op($op, $nm, *@args, :$node)   {  qast-op($op,  qast-spair('name', $nm), |@args) }
sub qast($class-nm, *@args, :$node) {
     QAST::Op.new( :op<callmethod>, :name<new>,
        QAST::WVal.new( :value($*W.find_sym(['QAST', $class-nm]))),
        |@args)
}

grammar AST::Grammar is HLL::Grammar {
    rule TOP {  <.ws> <EXPR>   }
    token term:sym<number>  {  [$<min>='-']? <number=.LANG('MAIN', 'number')> }
}

class AST::Actions is HLL::Actions {
    method TOP($/) {
        make $<EXPR>.ast;
    }
    method term:sym<number>($/) {
        my $is-num   := nqp::index(~$/, '.') >= 0;
        my $val      := $<min> ?? -$/ !! +$/;
        my $class-nm := $is-num ??      'NVal'     !!      'IVal';
        make qast-val($class-nm, $val);
   }
}
