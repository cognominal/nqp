# checking `.!name`/`.!$name`/`.!@name`/`.!%name` sugar for attribute
# access, and that `.!name(...)` (argument list present) still is an
# ordinary private method call.

plan(20);

class DAObj {
    has $!x;
    has int $!n;
    has num $!f;
    has str $!s;
    has @!items;
    has %!map;

    method setx($v)     { $!x := $v; self }
    method getx()       { $!x }
    method setn(int $v) { $!n := $v; self }
    method getn()       { $!n }
    method setf(num $v) { $!f := $v; self }
    method getf()       { $!f }
    method sets(str $v) { $!s := $v; self }
    method gets()       { $!s }
    method setitems($v) { @!items := $v; self }
    method setmap($v)   { %!map := $v; self }

    method !secret()      { 'shh' }
    method !add(int $a, int $b) { $a + $b }
}

my DAObj $o := DAObj.new;

## $-sigil object attribute: bare `.!x` is sugar for `.!$x`.
$o.setx(42);
ok( $o.!x == nqp::getattr($o, DAObj, '$!x'), 'bare .!x reads like nqp::getattr' );
ok( $o.!$x == $o.!x, '.!$x (explicit sigil) same as bare .!x' );
$o.!x := 43;
ok( nqp::getattr($o, DAObj, '$!x') == 43, '.!x := 43 writes like nqp::bindattr' );
ok( $o.getx() == 43, 'the write is visible through the ordinary accessor' );

## $-sigil native attributes pick the native getattr/bindattr variant.
$o.setn(7);
ok( $o.!n == nqp::getattr_i($o, DAObj, '$!n'), '.!n (native int) reads like nqp::getattr_i' );
$o.!n := 70;
ok( $o.getn() == 70, '.!n := 70 writes like nqp::bindattr_i' );

$o.setf(1.5e0);
ok( $o.!f == nqp::getattr_n($o, DAObj, '$!f'), '.!f (native num) reads like nqp::getattr_n' );
$o.!f := 2.5e0;
ok( $o.getf() == 2.5e0, '.!f := 2.5e0 writes like nqp::bindattr_n' );

$o.sets('hello');
is( $o.!s, nqp::getattr_s($o, DAObj, '$!s'), '.!s (native str) reads like nqp::getattr_s' );
$o.!s := 'world';
is( $o.gets(), 'world', ".!s := 'world' writes like nqp::bindattr_s" );

## @/%-sigil attributes: plain getattr/bindattr for the container itself,
## composing with the -[ ]/-<>/-{ } subscript sugar for element access.
$o.setitems([1,2,3]);
ok( $o.!@items-[1] == 2, '.!@items-[1] reads an element of the container attribute' );
$o.!@items-[1] := 99;
ok( $o.!@items-[1] == 99, '.!@items-[1] := 99 writes through the container attribute' );
$o.!@items := [7,8,9];
ok( $o.!@items-[0] == 7, '.!@items := [...] rebinds the whole container attribute' );

$o.setmap(nqp::hash('a', 1, 'b', 2));
ok( $o.!%map-<a> == 1, '.!%map-<a> reads an element of the container attribute' );
$o.!%map-{'a'} := 5;
ok( $o.!%map-<a> == 5, '.!%map-{...} := 5 writes through the container attribute' );

## `.!name(...)` -- argument list present, even empty -- stays an
## ordinary private method call, not attribute access.
is( $o.!secret(), 'shh', '.!secret() (empty parens) is a private method call' );
ok( $o.!add(3,4) == 7, '.!add(3,4) is a private method call with arguments' );

## Non-regression: ordinary method calls, HOW/WHAT/WHO/REPR, and quoted
## method-name calls are unaffected by the dotty grammar change.
class DAPlain { method greet() { 'hi' } }
my $p := DAPlain.new;
is( $p.greet(), 'hi', 'ordinary .method(...) calls still work' );
is( $p.HOW.name($p), 'DAPlain', '.HOW still works' );
is( $p."greet"(), 'hi', 'quoted method-name calls still work' );
