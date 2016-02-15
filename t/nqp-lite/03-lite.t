plan(11);
my @a;
my %a;
sub null($a, $msg) { ok($a.HOW.name($a) eq 'VMNull', $msg)  };
ok( @a[0] ~~ NQPMu, '@a[0] ~~ NQPMu');
null( @a-[0], 'unexistent @a-[0]');
null( %a-<0>, 'unexistent %a-<0>');
null( %a-{"0"}, 'unexistent %a-{"0"}');
nqp::push(@a, 42);
ok(@a-[0] == 42, '@a-[0]');
%a<0> := 42;
ok(%a-<0> == 42, '%a-<0>]');
ok(%a-{"0"} == 42, '%a-{"0"}');
ok(@a[0] :exists, '@a[0] :exists');
ok(@a-[0] :exists, '@a-[0] :exists');
%a-<0> :delete;
ok(!%a-<0> :exists, '!%a-<0> :exists');
%a<0> := 42;
%a-{"0"} :delete;
ok(!%a-{"0"} :exists,  '!%a-{"0"} :exists');

grammar A is HLL::Grammar {
   INIT {
        A.O(':prec<x=>, :assoc<unary>', '%autoincrement');
   }

    token TOP {   <EXPR>     }
    token term:sym<int> { \d+ }
    token postfix:sym<++> { <sym> <O('%autoincrement, :recall')> }
}

class A-actions is HLL::Actions {
  method TOP($/)             { make $<EXPR>.ast }
    method term:sym<int>($/)    {   make +~$/;   }
    method postfix:sym<++>($/, $recall?) {
       return 0 unless $recall;
       make $/[0]+1;
    }
}

my $a := A.parse('41++', :actions(A-actions)).ast;
ok($a == 42,  "<O('... :recall')>");


