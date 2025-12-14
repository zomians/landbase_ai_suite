// Import and register all your controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.

import { application } from "./application"

// Manually import controllers
import SolidusStripePaymentController from "./solidus_stripe_payment_controller"
import SolidusStripeConfirmController from "./solidus_stripe_confirm_controller"

application.register("solidus-stripe-payment", SolidusStripePaymentController)
application.register("solidus-stripe-confirm", SolidusStripeConfirmController)
