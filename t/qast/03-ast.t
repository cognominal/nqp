plan(25);


sub test($qast, &test) {
    $qast := QAST::Block.new($qast);
    my $code := nqp::getcomp('nqp').compile($qast, :from<ast>); # :optimize<off>);
#    say("-------$code.dump()\n------");
#    say($code.HOW.name($code));
    &test($code());
}


sub what($v) { $v.HOW.name($v) }
sub swhat($v, $s = '') { print("$s : ") if $s; say(what($v)) }
my $int;
my $num;
my $str;

$int := AST +42;    ok( $int == 42    &&  nqp::isint($int), 'AST +42' );
$int := AST +-42;   ok( $int == -42   &&  nqp::isint($int), 'AST +-42' );
$num := AST +42.0;  ok( $num == 42.0  &&  nqp::isnum($num), 'AST +42' );
$num := AST +-42.0; ok( $num == -42.0 &&  nqp::isnum($num), 'AST +-42' );

test((AST 42),   -> $v { ok(nqp::isint($v) && $v == 42,   'AST 42')    });
test((AST -42),   -> $v { ok(nqp::isint($v) && $v == -42, 'AST -42')   });
test((AST 42.0), -> $v { ok(nqp::isnum($v) && $v == 42.0, 'AST 42.0')  });
test((AST '42'), -> $v { ok(nqp::isstr($v) && $v eq 42,   "AST '42'")  });
test((AST "42"), -> $v { ok(nqp::isstr($v) && $v eq 42,   'AST "42"')  });

test((AST (42)), -> $v { ok(nqp::isint($v) && $v == 42, 'AST (42)')  });
test((AST {42}), -> $v { ok(nqp::isint($v) && $v == 42, 'AST {42}')  });
test((AST nan),  -> $v { ok(nqp::isnum($v) , 'AST nan')});
test((AST nan()),  -> $v { ok(nqp::isnum($v) , 'AST nan()')});
# correct?
test((AST nan ()),  -> $v { ok(nqp::isnum($v) , 'AST nan ()')});
test((AST chr 42), -> $v { ok($v eq '*', 'AST chr 42')});
test((AST chr(42)), -> $v { ok($v eq '*', 'AST chr(42)')});
test((AST chr (42)), -> $v { ok($v eq '*', 'AST chr (42)')});


test((AST concat 4, 2),  -> $v { ok(nqp::isstr($v) && $v eq '42' , 'AST concat 4, 2')});
test((AST concat(4, 2)),  -> $v { ok(nqp::isstr($v) && $v eq '42' , 'AST concat(4, 2)')});
test((AST concat (4, 2)),  -> $v { ok(nqp::isstr($v) && $v eq '42' , 'AST concat (4, 2)')});

#test((AST IVal 42),   -> $v { ok(nqp::isint($v) && $v == 42,   'AST IVal 42')    });


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



ok("42$var" eq '4242', 'HL-var: AST "42$var"');


$var := '$var-name';
$ast := AST $$var;
ok( nqp::istype($ast, QAST::Var), 'AST $$var  is a QAST::Var' )
