defmodule Cerberus.Driver do
  @moduledoc false

  alias Cerberus.Locator
  alias Cerberus.Options
  alias Cerberus.Session

  @type session_t :: Session.t()
  @type observed :: Session.observed()
  @type op_ok :: {:ok, session_t(), observed()}
  @type op_error :: {:error, session_t(), observed(), String.t()}
  @type click_opts :: Options.click_opts()
  @type fill_in_input_value :: Options.fill_in_value()
  @type fill_in_value :: String.t()
  @type fill_in_opts :: Options.fill_in_opts()
  @type check_opts :: Options.check_opts()
  @type select_opts :: Options.select_opts()
  @type choose_opts :: Options.choose_opts()
  @type upload_path :: String.t()
  @type upload_opts :: Options.upload_opts()
  @type submit_opts :: Options.submit_opts()
  @type assert_opts :: Options.assert_opts()
  @type assert_value_opts :: Options.assert_value_opts()
  @type assert_download_opts :: Options.assert_download_opts()
  @type path_opts :: Options.path_opts()
  @type visit_opts :: Options.visit_opts()
  @type within_callback :: (Session.t() -> Session.t())
  @type path_operation :: :assert_path | :refute_path

  @callback new_session(keyword()) :: session_t()
  @callback open_tab(session_t()) :: session_t()
  @callback switch_tab(session_t(), Session.t()) :: Session.t()
  @callback close_tab(session_t()) :: session_t()
  @callback open_browser(session_t(), (String.t() -> any())) :: session_t()
  @callback render_html(session_t(), (LazyHTML.t() -> any())) :: session_t()
  @callback unwrap(session_t(), (term() -> term())) :: session_t()
  @callback within(session_t(), Locator.t(), within_callback()) :: Session.t()
  @callback visit(session_t(), String.t(), visit_opts()) :: session_t()
  @callback click(session_t(), Locator.t(), click_opts()) :: op_ok() | op_error()
  @callback fill_in(session_t(), Locator.t(), fill_in_value(), fill_in_opts()) ::
              op_ok() | op_error()
  @callback select(session_t(), Locator.t(), select_opts()) :: op_ok() | op_error()
  @callback choose(session_t(), Locator.t(), choose_opts()) :: op_ok() | op_error()
  @callback check(session_t(), Locator.t(), check_opts()) :: op_ok() | op_error()
  @callback uncheck(session_t(), Locator.t(), check_opts()) :: op_ok() | op_error()
  @callback upload(session_t(), Locator.t(), upload_path(), upload_opts()) :: op_ok() | op_error()
  @callback submit_active_form(session_t(), submit_opts()) :: op_ok() | op_error()
  @callback submit(session_t(), Locator.t(), submit_opts()) :: op_ok() | op_error()
  @callback assert_has(session_t(), Locator.t(), assert_opts()) :: op_ok() | op_error()
  @callback refute_has(session_t(), Locator.t(), assert_opts()) :: op_ok() | op_error()
  @callback assert_value(session_t(), Locator.t(), String.t() | Regex.t(), assert_value_opts()) :: op_ok() | op_error()
  @callback refute_value(session_t(), Locator.t(), String.t() | Regex.t(), assert_value_opts()) :: op_ok() | op_error()
  @callback assert_download(session_t(), String.t(), assert_download_opts()) :: session_t()
  @callback default_timeout_ms(session_t()) :: non_neg_integer()
  @callback run_path_assertion(session_t(), String.t() | Regex.t(), path_opts(), non_neg_integer(), path_operation()) ::
              session_t()
  @callback assert_path(session_t(), String.t() | Regex.t(), path_opts()) :: op_ok() | op_error()
  @callback refute_path(session_t(), String.t() | Regex.t(), path_opts()) :: op_ok() | op_error()
end
