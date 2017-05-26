sub what($v) { $v.HOW.name($v) }
sub swhat($v, $s = '') { print("$s : ") if $s; say(what($v)) }xs

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
sub qq-wval($val, $search=0) {
        $val :=  QAST::Op.new(:op<callmethod>, :name<find_sym>,
           QAST::Var.new(:name<$*W>, :scope<contextual>),
           QAST::Op.new(:op<split>, QAST::SVal.new(:value(~$val))));
#   $val := $*W.find_sym(nqp::split('::', ~$val)) 
        qq-val(QAST::WVal, $val)
}

sub qq-op($op, *@args, :$node)              {     qq('Op', q-spair('op',   $op), |@args) }
sub qq-named-op($op, $nm, *@args, :$node)   {  qq-op($op,  q-spair('name', $nm), |@args) }
sub qq($class, *@args, :$node) {
     $class := ~$class if $class ~~ NQPMatch;
     $class := $*W.find_sym(['QAST', $class]) if nqp::isstr($class);
     QAST::Op.new( :op<callmethod>, :name<new>,
         QAST::WVal.new(:value($class )),
        |@args)
}


class AST {
   sub dump($n) {
      my $s := '';
      if $n ~~ QAST::IVal || $n ~~ QAST::NVal {
          $s := $s ~ $n.value;
      }
      $s;
   }
}


# We shove here commonalities between ast and atm grammars. Tentative
role AST::Grammar-Common {
    token value { <number> } # | <str >                                                    }
}

grammar AST::Grammar is HLL::Grammar does AST::Grammar-Common {
     INIT {
          AST::Grammar.O(':prec<y=>, :assoc<unary>',                         '%methodop');
      }

    rule TOP    {  :my $*AST := 1; <.ws> <EXPR>                                            }
    token term:sym<value>  { <value>                                                       }
    token number{  [$<prefix>='+']? [$<min>='-']? <num=.LANG('MAIN', 'number')>            }
}



class AST::Actions is HLL::Actions {
    method TOP($/) {
        %ast-vars := nqp::hash();
        make $<EXPR>.ast;
    }
    method term:sym<value>($/)     { make $<value>.ast                                     }
    method value($/)               { make $<str> ?? $<str>.ast !! $<number>.ast            }
    method number($/) {
        my $non-gen := $<prefix> || $*NON-GEN; 
        my $is-num  := nqp::index(~$<num>, '.') >= 0;
        my $val     := $<min> ?? -$<num> !! +$<num>;
        if $<prefix>  {
            my $ast :=  ($is-num ?? QAST::NVal !! QAST::IVal).new(:value($val));
            make $ast;
        } else {
            my &fun := $is-num ??  &qq-nval !! &qq-ival;
            make &fun($val);
        }
    }
}

sub gen-var($nm) {
   my $hash := $*W.find_sym($nm);
   my $ast = QAST::Var.new(:name($nm));
   for $hash {
        $value := $hash{$_};
        say("$_ $value")
        $ast."$_"($value);
   }
   swhat($ast, 'gen-var')
}


grammar ATM::Grammar is HLL::Grammar does AST::Grammar-Common {
    token TOP {
         :my str $*ATM-VAR := '$_';
#        [ <var=LANG('MAIN', 'variable')> ')' '~~' ]?
        <EXPR>
     }
     token number { <num=.LANG('MAIN', 'number')> }
}

class ATM::Actions is HLL::Actions {
    method TOP($/) {
         QAST::Var.new(:name<$_>, :scope<lexical>)
    }

    method number($/) {
        QAST::Op.new(:op<isint>, 
          QAST::Op.new(:op<callmethod>
    }

}

