# test file for ast and atm slangs
plan(15);

sub compile_qast($qast) {
    my $*QAST_BLOCK_NO_CLOSE := 1;
    # Turn off the optimizer as it can only handle things things nqp generates
    nqp::getcomp('nqp').compile(QAST::Block.new($qast), :from('ast'), :optimize('off'));
}
sub is_qast($qast, $value, $desc) {
    try {
        my $code := compile_qast($qast);
        is($code(), $value, $desc);
        CATCH { ok(0, 'Exception in is_qast: ' ~ $! ~ ", test: $desc") }
    }
}
sub is_qast_args($qast, @args, $value, $desc) {
    try {
        my $code := compile_qast($qast);
        is($code(|@args), $value, $desc);
        CATCH { ok(0, 'Exception in is_qast_arg: ' ~ $! ~ ", test: $desc") }
    }
}
sub test_qast_result($qast, $tester, $desc) {
    try {
        my $code := compile_qast($qast);
        say("res\n" ~ $qast.dump);
        ok($tester($code(), $desc));
        CATCH { ok(0, 'Compilation failure in test_qast_result: ' ~ $!) }
    }
}


ok((AST 42).value == 42, 'AST 42');
is_qast((AST 42), 42, 'AST 42');
is_qast((AST (42)), 42, 'AST (42)');
ok(nqp::istype((AST { 42 }), QAST::Block),  '(AST  {42}) is a QAST::Block');
ok(nqp::istype((AST -{ 42 }), QAST::Stmts), '(AST -{42}) is a QAST::Stmts');
ok(nqp::istype((AST Block 42 ), QAST::Block),  '(AST Block 42) is a QAST::Block');
ok(nqp::istype((AST Stmts 42 ), QAST::Stmts),  '(AST Block 42) is a QAST::Stmts');
# is_qast((AST Block :immediate 42 ), 42, 'AST Block 42' );


#  Lots of sugar for splicing so as to avoid the crude : AST {{ an-nqp-expr }}
# syntax highlighting should evenutally make clear what is spliced.

my $ast-n := AST 42;
my @ast-n := [AST 42];
is_qast((AST {{$ast-n}}),    42,         'explicit splicing: AST {{$n}} with $n    := AST 42');
is_qast((AST $ast-n),        42,         'implicit splicing: AST $ast-n     with $ast-n    := AST 42');
is_qast((AST @ast-n[0]),     42,         'implicit splicing: AST @ast-n[0]  with @ast-n[0] := AST 42');

# A short form on a leaf splices
is_qast((AST IVal 42),   42,             'AST IVal 42');

my $n := 42;
is_qast((AST +42),            42,         'AST     +42');
is_qast((AST IVal +42),       42,         'AST IVal +42');
is_qast((AST IVal 31 + 11),   42,         'AST IVal 31 + 11');
# is_qast((AST +$n),            42,         'AST      +$n');
is_qast((AST IVal +$n),       42,         'AST IVal +$n');
