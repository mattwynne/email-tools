// Import Prism.js core
import Prism from "prismjs"

// Optionally import Prism themes and plugins if you need them
import "prismjs/themes/prism.css" // Basic theme
// import 'prismjs/themes/prism-tomorrow.css'; // Dark theme

// Load languages you need, for example:
import "prismjs/components/prism-json" // For JSON syntax highlighting

// If you want to use any plugins
// import 'prismjs/plugins/line-numbers/prism-line-numbers.css';
// import 'prismjs/plugins/line-numbers/prism-line-numbers.js';

// Initialize Prism (if needed, Prism auto-initializes by default)
Prism.highlightAll()


// Import Highlight.js core
import hljs from 'highlight.js';

// Optionally import the style you want to use
import 'highlight.js/styles/default.css'; // Default theme
// import 'highlight.js/styles/github.css'; // GitHub theme

// Optionally load languages if you only want to include specific ones
// import json from 'highlight.js/lib/languages/json';
// hljs.registerLanguage('json', json);

// Initialize Highlight.js (automatically highlights all <pre><code> blocks)
document.addEventListener('DOMContentLoaded', (event) => {
  hljs.highlightAll();
});

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300))
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
