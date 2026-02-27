(() => {
  const connect = () => {
    const csrf =
      document.querySelector("meta[name='csrf-token']")?.getAttribute("content") || "";

    const liveSocket = new LiveView.LiveSocket("/live", Phoenix.Socket, {
      params: {_csrf_token: csrf}
    });

    liveSocket.connect();
    window.liveSocket = liveSocket;
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", connect, {once: true});
  } else {
    connect();
  }
})();
