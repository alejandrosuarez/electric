defmodule Electric.ShapeCache.StorageTest do
  use ExUnit.Case, async: true
  use Support.Mock

  alias Electric.ShapeCache.Storage
  alias Electric.Replication.LogOffset

  import Mox

  setup :verify_on_exit!

  test "should pass through the calls to the storage module" do
    storage = {Mock.Storage, :opts}
    shape_handle = "test"

    Mock.Storage
    |> Mox.stub(:for_shape, fn ^shape_handle, :opts -> {shape_handle, :opts} end)
    |> Mox.expect(:make_new_snapshot!, fn _, {^shape_handle, :opts} -> :ok end)
    |> Mox.expect(:snapshot_started?, fn {^shape_handle, :opts} -> true end)
    |> Mox.expect(:append_to_log!, fn _, {^shape_handle, :opts} -> :ok end)
    |> Mox.expect(:get_total_disk_usage, fn :opts -> 0 end)
    |> Mox.expect(:get_log_stream, fn _, _, {^shape_handle, :opts} -> [] end)

    shape_storage = Storage.for_shape(shape_handle, storage)

    Storage.make_new_snapshot!([], shape_storage)
    Storage.snapshot_started?(shape_storage)
    Storage.append_to_log!([], shape_storage)
    Storage.get_log_stream(LogOffset.first(), shape_storage)
    Storage.get_total_disk_usage(storage)
  end

  test "get_log_stream/4 correctly guards offset ordering" do
    storage = {Mock.Storage, :opts}
    shape_handle = "test"

    Mock.Storage
    |> Mox.stub(:for_shape, fn shape_handle, :opts -> {shape_handle, :opts} end)
    |> Mox.expect(:get_log_stream, fn _, _, {_shape_handle, :opts} -> [] end)

    l1 = LogOffset.new(26_877_408, 10)
    l2 = LogOffset.new(26_877_648, 0)

    shape_storage = Storage.for_shape(shape_handle, storage)

    Storage.get_log_stream(l1, l2, shape_storage)

    assert_raise FunctionClauseError, fn ->
      Storage.get_log_stream(l2, l1, shape_storage)
    end
  end
end
