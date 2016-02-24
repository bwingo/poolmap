defmodule ParallelController do
  use GenServer

  def new, do: GenServer.start_link(__MODULE__, :new)

  def setup(_pid, _collection, _function, limit) when false == is_integer(limit), do: {:error, "4th element is the limit of workers. It needs to be an integer."}
  def setup(_pid, collection, _function, _limit) when false == is_list(collection), do: {:error, "2ed element is the collection. It needs to be a list."}
  def setup(_pid, _collection, function, _limit) when false == is_function(function), do: {:error, "3ed element is the function. It needs to be a function."}
  def setup(pid, collection, function, limit), do: GenServer.call(pid, {:setup, {collection, function, limit}})

  def worker_finished(pid), do: GenServer.cast(pid, :worker_finished)

  def all_work_done(pid), do: Genserver.cast(pid, :all_done)

  def get_results(pid), do: GenServer.call(pid, :get)

  # GenServer callbacks
  def handle_cast(:worker_finished, {collection, function, collector_pid, worker_counter_pid, done?}) do
    WorkerCounter.remove_worker(worker_counter_pid)
    ncollection = case collection do
      []   -> []
      list -> start_worker_from_list(function, list, collector_pid, worker_counter_pid)
    end
    {:noreply, {ncollection, function, collector_pid, worker_counter_pid, done?}}
  end

  def handle_cast(:all_done, {collection, function, collector_pid, worker_counter_pid, done?}) do
    {:noreply, {collection, function, collector_pid, worker_counter_pid, true}}
  end

  def handle_call({:setup, {collection, function, limit}}, _from, _state) do
    {:ok, collector_pid} = Collector.new(self)
    Collector.setup(collector_pid, self, Enum.count(collection))

    {:ok, worker_counter_pid} = WorkerCounter.new(limit)
    WorkerCounter.set_limit(worker_counter_pid, limit)
    {_, updated_collection} = start_initial_workers(collection, function, collector_pid, worker_counter_pid, limit)

    {:reply, updated_collection, {updated_collection, function, collector_pid, worker_counter_pid, false}}
  end

  def handle_call(:get, _from, {collection, function, collector_pid, worker_counter_pid, done?}) do
    no_workers = WorkerCounter.get(worker_counter_pid) == 0
    if done? && no_workers do
      {:reply, collector_pid, {collection, function, collector_pid, worker_counter_pid, done?}}
    else
      {:reply, false, {collection, function, collector_pid, worker_counter_pid, done?}}
    end
  end

  # Support functions
  defp start_initial_workers(collection, function, collector_pid, worker_counter_pid, limit) do
    Enum.reduce(collection, {limit, []}, fn(item, {acc, work_not_started}) ->
      case acc do
        0 -> {0, work_not_started ++ [item]}
        _ ->
          start_worker(function, item, collector_pid, worker_counter_pid)
          {acc - 1, work_not_started}
      end
    end)
  end

  defp start_worker_from_list(function, [head|tail], collector_pid, worker_counter_pid) do
    start_worker(function, head, collector_pid, worker_counter_pid)
    tail
  end

  defp start_worker(function, item, collector_pid, worker_counter_pid) do
    # this handels if worker limit is reached.
    case WorkerCounter.worker_started(worker_counter_pid) do
      :limit_reached -> :ok
      :ok            -> spawn_link fn -> Collector.add_result(collector_pid, {self, function.(item)}) end
    end
  end
end
