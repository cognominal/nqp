ok(nqp::istype((AST 42),  QAST::IVal), 'AST 42   is IVAL');
ok(nqp::istype((AST 42.0), QAST::NVal), 'AST 42.0   is NVAL');
ok((AST 42).value == 42, 'AST 42   gives 42');
ok((AST 42.0).value == 42.0, 'AST 42.0  gives 42.0');
