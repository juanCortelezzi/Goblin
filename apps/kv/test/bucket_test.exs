defmodule KV.BucketTest do
  use ExUnit.Case, async: true
  doctest KV.Bucket

  alias KV.Bucket

  setup do
    bucket = start_supervised!({Bucket, %{}})
    %{bucket: bucket}
  end

  test "set value in kv", %{bucket: bucket} do
    assert Bucket.get(bucket, "count") == nil
    Bucket.set(bucket, "count", 2)
    assert Bucket.get(bucket, "count") == 2
  end

  test "getset value in kv", %{bucket: bucket} do
    assert Bucket.getset(bucket, "count", 2) == nil
    assert Bucket.getset(bucket, "count", 4) == 2
    assert Bucket.get(bucket, "count") == 4
  end

  test "getdel value in kv", %{bucket: bucket} do
    Bucket.set(bucket, "count", 2)
    assert Bucket.getdel(bucket, "count") == 2
    assert Bucket.get(bucket, "count") == nil
  end
end
