# checking `foo-(...)` sugar for `nqp::foo(...)`

plan(14);

## The dash form should be equivalent to the `nqp::` form.
ok( add_i-(3,4) == nqp::add_i(3,4), 'add_i-(3,4) same as nqp::add_i(3,4)' );
ok( sub_i-(10,3) == nqp::sub_i(10,3), 'sub_i-(10,3) same as nqp::sub_i(10,3)' );
is( concat-('foo','bar'), nqp::concat('foo','bar'), 'concat-(...) same as nqp::concat(...)' );

## Zero-arg op call.
ok( isnull-(null-()) == 1, 'null-() then isnull-() reports null' );
ok( isnull-(list-()) == 0, 'list-() is not null' );

## Multiple args, and an op with more than two args.
my @a := list-(1,2,3);
ok( elems-(@a) == 3, 'list-(1,2,3) has 3 elements' );
ok( atpos-(@a,1) == 2, 'atpos-(@a,1) reads element' );
bindpos-(@a,1,42);
ok( atpos-(@a,1) == 42, 'bindpos-(@a,1,42) writes element' );

## The dash must be immediately followed by `(` to trigger the sugar;
## ordinary subtraction, with or without whitespace, must still work
## even when the left operand is an identifier bound to a variable.
my $x := 10;
ok( $x-(3) == 7, '$x-(3) is still subtraction, not sugar' );
ok( $x - (3+2) == 5, '$x - (3+2) parenthesized subtraction still works' );
ok( $x-3 == 7, '$x-3 (no parens) is still subtraction' );
ok( 10-9 == 1, '10-9 (no parens, no sugar target) is still subtraction' );

## `nqp::op` special-cased ops (like `handle`) must behave the same
## whether called via `nqp::` or via the dash sugar.
sub block_that_dies() {
    nqp::die('oops');
}
sub the_catch_handler() {
    99
}
sub via_nqp() {
    nqp::handle(block_that_dies(), 'CATCH', the_catch_handler());
}
sub via_dash() {
    handle-(block_that_dies(), 'CATCH', the_catch_handler());
}
ok( via_nqp() == 99, 'nqp::handle CATCH branch runs' );
ok( via_dash() == 99, 'handle-(...) CATCH branch runs the same way' );
