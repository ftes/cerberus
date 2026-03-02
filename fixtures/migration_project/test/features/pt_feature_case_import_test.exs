defmodule MigrationFixtureWeb.PtFeatureCaseImportTest do
  use MigrationFixtureWeb.FeatureCase

  test "pt_feature_case_import", %{conn: conn} do
    expected = "Search"

    conn
    |> visit("/search")
    |> assert_has("h1", text: expected)
  end
end
