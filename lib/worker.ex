defmodule WorkerCounter do
  use GenServer

  # API
  def new, do: GenServer.start_link(__MODULE__)

  def setup(pid, limit), do: GenServer.cast(pid, {:setup, limit})

  def worker_started(pid), do: GenServer.call(pid, :add)

  def worker_finished(pid), do: GenServer.cast(pid, :remove)

  #NOTE set_limit doesn't handle if current workers are over new limit.
  def set_limit(pid, new_limit), do: GenServer.call(pid, {:set, new_limit})

  def get(pid), do: GenServer.call(pid, :get)

  # GenServer callbacks
  def handle_cast({:setup, worker_limit}, _state) do
    {:noreply, {worker_limit, 0}}
  end

  def handle_cast(:remove, {worker_limit, running_workers}) do
    {:noreply, {worker_limit, running_workers - 1}}
  end

  def handle_cast({:set, new_limit}, {_worker_limit, running_workers}) do
    {:noreply, {new_limit, running_workers}}
  end

  def handle_call(:get, _from, worker_data) do
    {:reply, worker_data, worker_data}
  end

  def handle_call(:add, _from, {worker_limit, running_workers}) do
    if running_workers >= worker_limit do
      {:reply, :limit_reached, {worker_limit, running_workers}}
    else
      {:reply, :ok, {worker_limit, running_workers + 1}}
    end
  end

end
