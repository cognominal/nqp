
plan(1);

sub test($qast, &test) {
    $qast := QAST::Block.new($qast);
    my $code := nqp::getcomp('nqp').compile($qast, :from<ast>); # :optimize<off>);
#    say("-------$code.dump()\n------");
#    say($code.HOW.name($code));
    &test($code());
}


sub what($v) { $v.HOW.name($v) }
sub swhat($v, $s = '') { print("$s : ") if $s; say(what($v)) }

test((AST 42),   -> $v { ok(nqp::isint($v) && $v == 42,   'AST 42')    });
test((AST 42.0), -> $v { ok(nqp::isnum($v) && $v == 42.0, 'AST 42.0')  });
test((AST '42'), -> $v { ok(nqp::isstr($v) && $v eq 42,   "AST '42'")  });

test((AST (42)), -> $v { ok(nqp::isint($v) && $v == 42, 'AST (42)')  });
test((AST {42}), -> $v { ok(nqp::isint($v) && $v == 42, 'AST {42}')  });
test((AST {{42}}), -> $v { ok(nqp::isint($v) && $v == 42, 'AST {{42}}')  });


my $var := 42;
my $ast := AST $var;
ok($ast == 42, 'HL-var: AST $var');
$var := '$var-name';
$ast := AST $$var;
ok( nqp::istype($ast, QAST::Var), 'AST $$var  is a QAST::Var' )
