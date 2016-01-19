plan(4);
grammar A is HLL::Grammar {
  INIT {
    A.O(':prec<y=>, :assoc<unary>', '%methodop');
    A.O(':prec<t=>, :assoc<left>',  '%additive');
  }


  token              TOP   { <EXPR>                                     }
         term          a   { a                                          }
  token  term          ba  { b <a>                                      }
         postcircumfix [ ] {  '[' <.ws> <EXPR> ']'    <O('%methodop')>  }
         infix         *   {   '*'                    <O('%additive')>  }  
}

ok( A.parse('a')    eq 'a',      '      term          a   { ... }'  );
ok( A.parse('ba')   eq 'ba',     'token term          ba  { ... }'  );
ok( A.parse('a[a]') eq 'a[a]',   '      postcircumfix [ ] { ... }'  );
ok( A.parse('a * a') eq 'a * a', '      infix         *   { ... }'  );
ok( A.parse('a*a') eq 'a*a',     '      infix         *   { ... }'  );