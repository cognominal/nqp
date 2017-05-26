plan(4);

my $ast := AST 42;
ok($ast.value == 42, AST 42);
my $atm :=  if ATM 42