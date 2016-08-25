defmodule Poolmap do
  @doc """
  pmap/2 maps over a collection and starts a process for each item and runs a funcion on/with the item.
  """
  def pmap(collection, function) do
    me = self
    Enum.map(collection, fn (elem) ->
      spawn_link fn -> (send me, { self, function.(elem) }) end
    end) |>
    Enum.map(fn (pid) ->
      receive do { ^pid, result } -> result end
    end)
  end

  @doc """
  pmap/3 maps over a collection and starts a process for each item and runs a funcion on/with the item.
  At any one point there will only be a limited number of processes working specified by an integer in the limit.
  """
  def pmap(collection, function, limit) do
    {:ok, controller_pid} = ParallelController.new
    ParallelController.setup(controller_pid, collection, function, limit)
    results = get_results(controller_pid)
    Process.exit(controller_pid, :normal) #killing the controller should kill all the other processes
    results
  end

  defp get_results(controller_pid) do
    case ParallelController.get_results(controller_pid) do
      false ->                             # this waits 5 ms and checks to see if the work is done agin
        :timer.sleep(5)
        get_results(controller_pid)
      pid -> Collector.retrive_result(pid) # this pulls the results
    end
  end
end
