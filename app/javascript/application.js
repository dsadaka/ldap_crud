// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// import "bootstrap"
import "@hotwired/turbo-rails"
import "controllers"
// Load Popper globally so Bootstrap finds it
import * as Popper from "popper"
window.Popper = Popper

// Now import Bootstrap
import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap

import { setupFormInteractivity } from "spam_user_form"
document.addEventListener("turbo:load", setupFormInteractivity);