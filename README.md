Poolmap                                                                                                                                                       
=======                                                                                                                                                       
                                                                                                                                                              
  pmap/2 maps over a collection and starts a process for each item and runs a funcion on/with the item.                                                       
                                                                                                                                                              
  pmap/3 maps over a collection and starts a process for each item and runs a funcion on/with the item. At any one point there will only be a limited number of processes working specified by an integer as the limit.

** TODO: Make it work. **
Getting error:                                                                                                                         
22:41:30.628 [error] beam/beam_load.c(1250): Error loading module 'Elixir.Genserver':

  module name in object code is Elixir.GenServer

** (EXIT from #PID<0.77.0>) an exception was raised:
    ** (UndefinedFunctionError) undefined function: Genserver.call/2 (module Genserver is not available)
        Genserver.call(#PID<0.79.0>, :all_done)
        (poolmap) lib/collector.ex:22: Collector.handle_cast/2
        (stdlib) gen_server.erl:593: :gen_server.try_dispatch/4
        (stdlib) gen_server.erl:659: :gen_server.handle_msg/5
        (stdlib) proc_lib.erl:237: :proc_lib.init_p_do_apply/3
