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
sub qq-wval($val, $search=0) {
        $val :=  QAST::Op.new(:op<callmethod>, :name<find_sym>,
           QAST::Op.new(:op<split>, QAST::SVal.new(:value(~$val))));
#   $val := $*W.find_sym(nqp::split('::', ~$val))
        qq-val(QAST::WVal, $val)
}

sub qq-op($op,            *@args, :$node) { qq('Op',    q-spair('op',   $op), |@args) }
sub qq-named-op($op, $nm, *@args, :$node) { qq-op($op,  q-spair('name', $nm), |@args) }


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



sub q-w() { q-var('$*W')  }

sub q-var($nm, :$scope = 'var', :$decl) {  QAST::Var.new(:name($nm), :scope($scope))  }

# for debug sake
sub what($v) { $v.HOW.name($v) }
sub swhat($v, $s = '') { print("$s : ") if $s; say(what($v)) }


# placeholders for ast and atm grammars and actions

role AST::Grammar-Common {
}

grammar AST::Grammar is HLL::Grammar does AST::Grammar-Common {
}
grammar AST::Actions is HLL::Actions {
}


grammar ATM::Grammar is HLL::Grammar does AST::Grammar-Common {
}

class ATM::Actions is HLL::Actions {
}
