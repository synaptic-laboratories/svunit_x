typedef class global_test_registry;


virtual class test;

  typedef class builder;
  typedef class adapter;


  local const adapter a = new(this);


  // <<SLL-FIX>> original upstream signature kept for review
  // protected static function bit register_test_builder(builder b, string typename);
  protected static function bit register_test_builder(input builder b, input string typename);
    full_name_extraction fn_extraction = new();
    string full_name = fn_extraction.get_full_name(typename);
    global_test_registry::get().register(b, full_name);

    return 1;
  endfunction


  pure virtual function string name();


  task run();
    set_up();
    test_body();
    tear_down();
  endtask


  protected virtual task set_up();
  endtask


  pure virtual protected task test_body();


  protected virtual task tear_down();
  endtask


  /* package */ function svunit_test get_adapter();
    return a;
  endfunction


  virtual class builder;
    pure virtual function test create();
  endclass


  class concrete_builder #(type T = test) extends builder;
    local static concrete_builder #(T) single_instance;

    static function concrete_builder #(T) get();
      if (single_instance == null)
        single_instance = new();
      return single_instance;
    endfunction

    virtual function T create();
      T result = new();
      return result;
    endfunction
  endclass


  class adapter extends svunit_test;

    local const test parent;

    // <<SLL-FIX>> original upstream signature kept for review
    // function new(test parent);
    function new(input test parent);
      super.new(parent.name());
      this.parent = parent;
    endfunction

    virtual task unit_test_setup();
      // Empty because `test::run()` already calls `test::set_up()`
    endtask

    virtual task run();
      parent.run();
    endtask

    virtual task unit_test_teardown();
      // Empty because `test::run()` already calls `test::tear_down()`
    endtask

  endclass

endclass
