defmodule Collector do
  use GenServer

  def new, do: GenServer.start_link(__MODULE__)
  
  def setup(pid, controller_pid, total_count), do: GenServer.cast(pid, {:setup, controller_pid, total_count})

  def add_result(pid, {worker_pid, result}), do: GenServer.cast(pid, {:add, {worker_pid, result}})

  def retrive_result(pid), do: GenServer.call(pid, :get)

  # GenServer callbacks
  defp handle_cast({:setup, controller_pid, total_count}, _state) do
    {:noreply, {controller_pid, total_count, []}}
  end

  defp handle_cast({:add, {worker_pid, result}}, {controller_pid, total_count, results}) do
    #NOTE kill worker first to prevent going over limit
    Process.exit(worker_pid, :kill)
    ParallelController.worker_finished(controller_pid)
    if Enum.count(results) + 1 >= total_count do
      ParallelController.all_work_done(controller_pid)
    end
    {:noreply, {controller_pid, total_count, results ++ [result]}}
  end

  defp handle_call(:get, _from, {controller_pid, total_count, results}) do
    {:reply, results, {controller_pid, total_count, results}}
  end

end
