class testcase extends svunit_testcase;

  // Keep queue typing here to match the parser-safe fork intent from the pre-move layout.
  typedef test::builder array_of_test_builder[$];


  local test::builder test_builders[$];


  // <<SLL-FIX>> original upstream signature kept for review
  // function new(string name);
  function new(input string name);
    super.new(name);
  endfunction


  // <<SLL-FIX>> original upstream signature kept for review
  // function void register(test::builder test_builder);
  function void register(input test::builder test_builder);
    test_builders.push_back(test_builder);
    add_test(test_builder.create().get_adapter());
  endfunction


  function array_of_test_builder get_test_builders();
    return test_builders;
  endfunction

endclass
