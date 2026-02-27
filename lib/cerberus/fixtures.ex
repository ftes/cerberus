defmodule Cerberus.Fixtures do
  @moduledoc """
  Shared deterministic fixture definitions for conformance tests.

  The fixtures are intentionally small and stable so static/live/browser drivers
  can be compared against the same expected behavior.
  """

  @articles_path "/articles"
  @counter_path "/live/counter"
  @static_redirect_path "/redirect/static"
  @live_redirect_path "/redirect/live"
  @live_redirects_path "/live/redirects"
  @oracle_mismatch_path "/oracle/mismatch"
  @oracle_live_mismatch_path "/live/oracle/mismatch"

  @articles_title "Articles"
  @articles_summary "This is an articles index page"
  @hidden_helper_text "Hidden helper text"

  @counter_title "Counter"
  @counter_label "Count"

  @increment_button "Increment"
  @counter_link "Counter"
  @articles_link "Articles"
  @redirect_to_articles_button "Redirect to Articles"
  @redirect_to_counter_button "Redirect to Counter"

  @oracle_static_marker "Oracle mismatch static fixture marker"
  @oracle_live_marker "Oracle mismatch live fixture marker"

  @spec routes() :: [map()]
  def routes do
    [
      %{path: @articles_path, kind: :static, purpose: :articles_page},
      %{path: @counter_path, kind: :live, purpose: :counter_page},
      %{path: @static_redirect_path, kind: :static_redirect, to: @articles_path},
      %{path: @live_redirect_path, kind: :static_redirect, to: @counter_path},
      %{path: @live_redirects_path, kind: :live, purpose: :live_redirect_actions},
      %{path: @oracle_mismatch_path, kind: :static, purpose: :oracle_mismatch_static},
      %{path: @oracle_live_mismatch_path, kind: :live, purpose: :oracle_mismatch_live}
    ]
  end

  def articles_path, do: @articles_path
  def counter_path, do: @counter_path
  def static_redirect_path, do: @static_redirect_path
  def live_redirect_path, do: @live_redirect_path
  def live_redirects_path, do: @live_redirects_path
  def oracle_mismatch_path, do: @oracle_mismatch_path
  def oracle_live_mismatch_path, do: @oracle_live_mismatch_path

  def articles_title, do: @articles_title
  def articles_summary, do: @articles_summary
  def hidden_helper_text, do: @hidden_helper_text

  def counter_title, do: @counter_title
  def counter_label, do: @counter_label
  def counter_text(count), do: "#{@counter_label}: #{count}"

  def increment_button, do: @increment_button
  def counter_link, do: @counter_link
  def articles_link, do: @articles_link
  def redirect_to_articles_button, do: @redirect_to_articles_button
  def redirect_to_counter_button, do: @redirect_to_counter_button

  def oracle_static_marker, do: @oracle_static_marker
  def oracle_live_marker, do: @oracle_live_marker
end
