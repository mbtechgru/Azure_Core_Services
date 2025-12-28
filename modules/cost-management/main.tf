
resource "azurerm_consumption_budget_subscription" "budget" {
  name            = "monthly-budget"
  subscription_id = var.subscription_id

  amount     = var.monthly_budget
  time_grain = "Monthly"

  time_period {
    start_date = "2025-01-01T00:00:00Z"
    end_date   = "2035-01-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    contact_emails = var.emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    contact_emails = var.emails
  }
}
