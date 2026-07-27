# checking `@a-[1]`/`%a-{'k'}`/`%a-<k>` sugar for the raw
# `nqp::atpos`/`nqp::atkey` (and `nqp::bindpos`/`nqp::bindkey`) ops.

plan(24);

## Array: read and write via the dashed sugar, compared against the
## direct nqp:: raw ops.
my @a := [10,20,30];
ok( @a-[1] == nqp::atpos(@a,1), '@a-[1] reads like nqp::atpos(@a,1)' );
@a-[1] := 99;
ok( nqp::atpos(@a,1) == 99, '@a-[1] := 99 writes like nqp::bindpos' );
ok( @a-[1] == 99, '@a-[1] sees the write back' );

## Hash: both bracket forms, read and write.
my %h := nqp::hash('x', 1, 'y', 2);
ok( %h-<x> == nqp::atkey(%h,'x'), '%h-<x> reads like nqp::atkey' );
ok( %h-{'y'} == nqp::atkey(%h,'y'), 'hash-brace form reads like nqp::atkey' );
%h-<x> := 42;
ok( nqp::atkey(%h,'x') == 42, '%h-<x> := 42 writes like nqp::bindkey' );
%h-{'y'} := 43;
ok( nqp::atkey(%h,'y') == 43, 'hash-brace form writes like nqp::bindkey' );

## Native :i/:n/:s markers pick the native op variant.
my @ai := nqp::list_i(1,2,3);
ok( @ai-:i[1] == nqp::atpos_i(@ai,1), '@ai-:i[1] reads like nqp::atpos_i' );
@ai-:i[1] := 42;
ok( nqp::atpos_i(@ai,1) == 42, '@ai-:i[1] := 42 writes like nqp::bindpos_i' );

my @an := nqp::list_n(1.5, 2.5);
ok( @an-:n[1] == nqp::atpos_n(@an,1), '@an-:n[1] reads like nqp::atpos_n' );
@an-:n[1] := 9.5;
ok( nqp::atpos_n(@an,1) == 9.5, '@an-:n[1] := 9.5 writes like nqp::bindpos_n' );

my @as := nqp::list_s('a','b');
is( @as-:s[0], nqp::atpos_s(@as,0), "@as-:s[0] reads like nqp::atpos_s" );
@as-:s[0] := 'z';
is( nqp::atpos_s(@as,0), 'z', "@as-:s[0] := 'z' writes like nqp::bindpos_s" );

## Non-regression: the plain (non-dashed) subscript forms must still
## work exactly as before -- they go through positional_get/bind and
## associative_get/bind, not the raw ops, but should read/write the
## same underlying storage.
my @b := [1,2,3];
ok( @b[1] == 2, 'plain @b[1] still works for reading' );
@b[1] := 55;
ok( @b[1] == 55, 'plain @b[1] := ... still works for writing' );
my %g := nqp::hash('k', 7);
ok( %g<k> == 7, 'plain %g<k> still works for reading' );
%g<k> := 8;
ok( %g<k> == 8, 'plain %g<k> := ... still works for writing' );
ok( %g{'k'} == 8, 'plain hash-brace form still works for reading' );

## Non-regression: the dash must be immediately followed by the
## delimiter to trigger the sugar -- ordinary subtraction, and array
## literals used as subtrahends, must still parse as before.
my $count := 10;
ok( $count - (3+2) == 5, '$count - (3+2) (spaced) is still subtraction' );
ok( $count-(3+2) == 5, '$count-(3+2) (no space) is still subtraction, not raw sugar' );
ok( $count-3 == 7, '$count-3 is still subtraction' );

## Mixing the dashed subscript sugar with an ordinary expression.
my @c := [5,10,15];
ok( @c-[0] + @c-[2] == 20, 'dashed subscripts compose in a larger expression' );

## Reads through the sugar reflect writes made via the plain form and
## vice versa -- both forms operate on the very same storage.
my @d := [1,2,3];
@d[0] := 100;
ok( @d-[0] == 100, 'raw read sees a write made through the plain postcircumfix' );
@d-[0] := 200;
ok( @d[0] == 200, 'plain read sees a write made through the raw sugar' );
