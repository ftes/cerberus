defmodule Cerberus.LiveViewBindingsTest do
  use ExUnit.Case, async: true

  alias Cerberus.LiveViewBindings

  test "returns true for raw phx-click event handlers" do
    assert LiveViewBindings.phx_click?("save")
  end

  test "returns true for push/navigate/patch JS commands" do
    assert LiveViewBindings.phx_click?(Jason.encode!([["push", %{"event" => "save"}]]))
    assert LiveViewBindings.phx_click?(Jason.encode!([["navigate", %{"href" => "/target"}]]))
    assert LiveViewBindings.phx_click?(Jason.encode!([["patch", %{"href" => "/target"}]]))
  end

  test "returns false for dispatch-only and true for mixed pipelines" do
    assert LiveViewBindings.phx_click?(Jason.encode!([["dispatch", %{"event" => "change"}], ["push", %{}]]))
    refute LiveViewBindings.phx_click?(Jason.encode!([["dispatch", %{"event" => "change"}]]))
  end
end
