# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "vendor/javascript"

# These two are required for Bootstrap
# Explicitly map the core modules
pin "bootstrap", to: "bootstrap.js"
pin "@popperjs/core", to: "popper.js"
pin "spam_user_form", to: "spam_user_form.js"