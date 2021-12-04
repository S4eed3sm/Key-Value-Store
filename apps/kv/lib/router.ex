defmodule KV.Router do
  require Logger
  def route(bucket, mod, fun, args) do
    first = :binary.first(bucket)
    {_enum, node_} =
      Enum.find(table(), fn {enum, _node} -> first in enum end) ||
        no_entry_error(bucket)

    if node_ == node() do
      apply(mod, fun, args)
    else
      {KV.RouterTasks, node_}
      |> Task.Supervisor.async(KV.Router, :route, [bucket, mod, fun, args])
      |> Task.await()
    end
  end

  defp no_entry_error(bucket) do
    raise "could not find entry for #{inspect(bucket)} in table #{inspect(table())}"
  end

  def table do
    # Replace computer-name with your local machine name
    Application.fetch_env!(:kv, :routing_table)
  end
end
