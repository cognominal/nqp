plan(25);
use QAST;
sub test($qast, &test, $msg='') {
    $qast := QAST::Block.new($qast);
    my $comp := nqp::getcomp('nqp');
    my $code := $comp.compile($qast, :from<ast>, :compunit_ok); # :optimize<off>);
    $code := $comp.backend().compunit_mainline($code);
    nqp::forceouterctx($code, nqp::ctxcaller(nqp::ctx));
    ok(&test($code()), $msg);
}

sub d($v) {  say($v.dump) }

#my $decl = QAST::Var.new(:name<$a>, :scope<lexical>, :decl<var));
# my $assign AST $$a = 1
# test((AST {{42}}), -> $v { ok(nqp::isint($v) && $v == 42, 'AST {{42}}')  });

#test((AST 43),       -> $v { nqp::isint($v) && $v == 43}, 'AST 43');
#say((AST 44).dump);

# test((AST IVal +42),   -> $v { ok(nqp::isint($v) && $v == 42,       'AST IVal +42')    });

#test((AST NVal +42.0),   -> $v { ok(nqp::isnum($v) && $v == 42.0,   'AST NVal 42.0')    });
#test((AST SVal ~'42'),   -> $v { ok(nqp::isstr($v) && $v eq '42',   "AST SVal "42")    });

my $ast; 
d(AST 1); 
# $ast := AST  $$b;
# d($ast);
class A {} ;
d(AST A::);
#ok($ast.name eq '$b', '$$b genvar name is \'$b\'');
#ok($ast.scope eq 'local', '$$b default scope is \'local\'');
#$ast := AST $$b :my;
#ok($ast.scope eq 'lexical', '$$b explicit scope is \'lexical\'');
# $ast := AST $$b :name('$foo');
# say($ast.name);

# $ast := AST NQPMu::;  
# say($ast.dump); 

#AST   :var;
# AST  $$e :param;


=begin END

sub what($v) { $v.HOW.name($v) }
sub swhat($v, $s = '') { print("$s : ") if $s; say(what($v)) }
my $int;
my $num;
my $str;

$int := AST +42;    ok( $int == 42    &&  nqp::isint($int), 'AST +42'  );
$int := AST +-42;   ok( $int == -42   &&  nqp::isint($int), 'AST +-42' );
$num := AST +42.0;  ok( $num == 42.0  &&  nqp::isnum($num), 'AST +42'  );
$num := AST +-42.0; ok( $num == -42.0 &&  nqp::isnum($num), 'AST +-42' );
$str := AST ~"42"; ok( $str eq "42" &&  nqp::isstr($str), 'AST ~"42"' );

macro a-test(} {
#   AST
}


my $a := 42;
my $str = AST ~$a; ok( $str eq "42" &&  nqp::isstr($str), 'my $a = 42; AST ~$a' );

my $ast = AST 42;
test((AST ~$ast),     -> $v { nqp::isstr($v) && $v eq 42   }, 'my $ast = AST ~$ast;');

#tok((AST 42),   -> $v { nqp::isint($v) && $v == 42 },   'AST 42');

test((AST 42),       -> $v { nqp::isint($v) && $v == 42   }, 'AST 42');
test((AST -42),      -> $v { nqp::isint($v) && $v == -42  }, 'AST -42');
test((AST 42.0),     -> $v { nqp::isnum($v) && $v == 42.0 }, 'AST 42.0');
test((AST '42'),     -> $v { nqp::isstr($v) && $v eq 42   }, "AST '42'");
test((AST "42"),     -> $v { nqp::isstr($v) && $v eq 42   }, 'AST "42"');

test((AST (42)),     -> $v { nqp::isint($v) && $v == 42   }, 'AST (42)');
test((AST {42}),     -> $v { nqp::isint($v) && $v == 42   }, 'AST {42}');
test((AST nan),      -> $v { nqp::isnum($v) } , 'AST nan' );
test((AST nan()),    -> $v { nqp::isnum($v) }, 'AST nan()');
# correct?
test((AST nan ()),   -> $v { nqp::isnum($v) }, 'AST nan ()');
test((AST chr 42),   -> $v { $v eq '*' }, 'AST chr 42');
test((AST chr(42)),  -> $v { $v eq '*' }, 'AST chr(42)');
test((AST chr (42)), -> $v { $v eq '*' }, 'AST chr (42)');


test((AST concat 4, 2),   -> $v { nqp::isstr($v) && $v eq '42'} , 'AST concat 4, 2'  );
test((AST concat(4, 2)),  -> $v { nqp::isstr($v) && $v eq '42'} , 'AST concat(4, 2)' );
test((AST concat (4, 2)), -> $v { nqp::isstr($v) && $v eq '42'} , 'AST concat (4, 2)');


test((AST IVal 42),   -> $v { ok(nqp::isint($v) && $v == 42,   'AST IVal 42')    });


# test((AST &hash() ),  -> $v { ok($v ~~ BooTHash , 'AST nan')});


# probably wrong
#test((AST {{42}}), -> $v { ok(nqp::isint($v) && $v == 42, 'AST {{42}}')  });
#test((AST {{{42}}}), -> $v { ok(nqp::isint($v) && $v == 42, 'AST {{{42}}}')  });


my $var := 42;
my $ast := AST $var;
ok($ast == 42, 'HL-var: AST $var');
class A { method a() { 42 }};
my $a := A.new;
my $ast1 := AST $a.a;
ok($ast1 == 42, 'HL-var: AST $a.a');
my @a := [42, 43];
my $ast2 := @a[0];
ok($ast == 42, 'HL-var: AST $a[0]');
{
  my $a := AST "42";
  test((AST "42$a"), -> $v { nqp::isstr($v) && $v eq '4242'} , 'my $a := AST "42" AST "42$a"');
}

{
  my str $a := "42";
  test((AST "42$a"), -> $v { nqp::isstr($v) && $v eq '4242'} , 'my str $a := "42"; AST "42$a"');
} 
#{
#my str $ast := "toto";
#my $ast3 := AST "42$ast";

#test($ast3, -> $v {$v eq '4242'}, 'HL-var: AST "42$ast"');


#$var := '$var-name';
#$ast := AST $$var;
#ok( nqp::istype($ast, QAST::Var), 'AST $$var  is a QAST::Var' )
=end END
