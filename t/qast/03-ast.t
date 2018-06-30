# test file for ast and atm slangs
plan(2);

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
