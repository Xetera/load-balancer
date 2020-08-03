defmodule LoadBalancerTest do
  use ExUnit.Case
  doctest LoadBalancer

  test "greets the world" do
    assert LoadBalancer.hello() == :world
  end
end
