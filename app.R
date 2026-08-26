library(shiny)
library(bslib)

source("R/config.R")
source("R/database.R")
source("R/market_series.R")
source("R/observation_store.R")
source("R/market_analytics.R")
source("R/risk_analytics.R")
source("R/dashboard_data.R")

config <- load_config()

connection <- connect_database(
  config$database_path
)

onStop(
  function() {
    disconnect_database(
      connection
    )
  }
)

dashboard_data <- prepare_dashboard_data(
  connection
)

market_metadata <-
  dashboard_data$market_metadata

analytics <-
  dashboard_data$analytics

risk_summary <-
  dashboard_data$risk_summary

market_snapshot <-
  get_latest_market_snapshot(
    analytics,
    market_metadata
  )

series_choices <- stats::setNames(
  market_metadata$series_key,
  market_metadata$display_name
)

minimum_date <- min(
  analytics$date,
  na.rm = TRUE
)

maximum_date <- max(
  analytics$date,
  na.rm = TRUE
)

ui <- bslib::page_navbar(
  title = "EnergyQuant",

  theme = bslib::bs_theme(
    version = 5,
    bootswatch = "flatly"
  ),

  bslib::nav_panel(
    "Overview",

    tags$div(
      class = "container-fluid pt-4",

      tags$h2(
        "Energy Market Intelligence"
      ),

      tags$p(
        "Live market monitoring, quantitative risk analytics and cross-market intelligence."
      ),

      fluidRow(
        column(
          width = 4,

          bslib::card(
            bslib::card_header(
              "Markets tracked"
            ),

            tags$h2(
              textOutput(
                "market_count",
                inline = TRUE
              )
            )
          )
        ),

        column(
          width = 4,

          bslib::card(
            bslib::card_header(
              "Latest market date"
            ),

            tags$h2(
              textOutput(
                "latest_date",
                inline = TRUE
              )
            )
          )
        ),

        column(
          width = 4,

          bslib::card(
            bslib::card_header(
              "Historical observations"
            ),

            tags$h2(
              textOutput(
                "observation_count",
                inline = TRUE
              )
            )
          )
        )
      ),

      tags$br(),

      bslib::card(
        bslib::card_header(
          "Latest market snapshot"
        ),

        tableOutput(
          "market_snapshot"
        )
      )
    )
  ),

  bslib::nav_panel(
    "Markets",

    tags$div(
      class = "container-fluid pt-4",

      fluidRow(
        column(
          width = 3,

          selectInput(
            inputId = "market",
            label = "Market",
            choices = series_choices,
            selected = "brent"
          ),

          dateRangeInput(
            inputId = "market_dates",
            label = "Date range",
            start = maximum_date - 365,
            end = maximum_date,
            min = minimum_date,
            max = maximum_date
          )
        ),

        column(
          width = 9,

          bslib::card(
            bslib::card_header(
              "Market price"
            ),

            plotOutput(
              "market_price_plot",
              height = "380px"
            )
          ),

          tags$br(),

          bslib::card(
            bslib::card_header(
              "30-observation annualised volatility"
            ),

            plotOutput(
              "market_volatility_plot",
              height = "320px"
            )
          )
        )
      )
    )
  ),

  bslib::nav_panel(
    "Risk",

    tags$div(
      class = "container-fluid pt-4",

      tags$h2(
        "Market Risk Analytics"
      ),

      tags$p(
        paste(
          "Historical VaR, Expected Shortfall,",
          "drawdown and risk-adjusted performance."
        )
      ),

      bslib::card(
        bslib::card_header(
          "Risk comparison"
        ),

        tableOutput(
          "risk_table"
        )
      )
    )
  )
)

server <- function(
  input,
  output,
  session
) {
  output$market_count <- renderText(
  {
    nrow(
      market_metadata
    )
  }
  )

  output$latest_date <- renderText(
  {
    format(
      maximum_date,
      "%d %b %Y"
    )
  }
  )

  output$observation_count <- renderText(
  {
    format(
      nrow(analytics),
      big.mark = ","
    )
  }
  )

  output$market_snapshot <- renderTable(
  {
    market_snapshot |>
      dplyr::transmute(
        Market = display_name,

        Date = date,

        Value = round(
          value,
          2
        ),

        Unit = unit,

        `Daily Return` =
          ifelse(
            is.na(simple_return),
            NA_character_,
            sprintf(
              "%.2f%%",
              simple_return * 100
            )
          ),

        `30D Volatility` =
          ifelse(
            is.na(
              rolling_volatility
            ),
            NA_character_,
            sprintf(
              "%.2f%%",
              rolling_volatility *
                100
            )
          )
      )
  },

    striped = TRUE,
    hover = TRUE
  )

  selected_market_data <- reactive(
  {
    req(
      input$market,
      input$market_dates
    )

    analytics |>
      dplyr::filter(
        series_key ==
          input$market,

        date >=
          input$market_dates[[1]],

        date <=
          input$market_dates[[2]]
      )
  }
  )

  output$market_price_plot <- renderPlot(
  {
    data <- selected_market_data()

    req(
      nrow(data) > 0
    )

    ggplot2::ggplot(
      data,
      ggplot2::aes(
        x = date,
        y = value
      )
    ) +
      ggplot2::geom_line(
        linewidth = 0.8
      ) +
      ggplot2::labs(
        x = NULL,
        y = "Market value"
      ) +
      ggplot2::theme_minimal(
        base_size = 13
      )
  }
  )

  output$market_volatility_plot <-
    renderPlot(
    {
      data <- selected_market_data() |>
        dplyr::filter(
          is.finite(
            rolling_volatility
          )
        )

      req(
        nrow(data) > 0
      )

      ggplot2::ggplot(
        data,
        ggplot2::aes(
          x = date,
          y = rolling_volatility *
            100
        )
      ) +
        ggplot2::geom_line(
          linewidth = 0.8
        ) +
        ggplot2::labs(
          x = NULL,
          y = "Annualised volatility (%)"
        ) +
        ggplot2::theme_minimal(
          base_size = 13
        )
    }
    )

  output$risk_table <- renderTable(
  {
    risk_summary |>
      dplyr::transmute(
        Market = display_name,

        `Annualised Return` =
          sprintf(
            "%.2f%%",
            annualised_return *
              100
          ),

        `Annualised Volatility` =
          sprintf(
            "%.2f%%",
            annualised_volatility *
              100
          ),

        `VaR 95%` =
          sprintf(
            "%.2f%%",
            value_at_risk *
              100
          ),

        `Expected Shortfall 95%` =
          sprintf(
            "%.2f%%",
            expected_shortfall *
              100
          ),

        `Maximum Drawdown` =
          sprintf(
            "%.2f%%",
            maximum_drawdown *
              100
          ),

        Sharpe = round(
          sharpe_ratio,
          2
        ),

        Sortino = round(
          sortino_ratio,
          2
        ),

        Calmar = round(
          calmar_ratio,
          2
        )
      )
  },

    striped = TRUE,
    hover = TRUE
  )
}

shinyApp(
  ui = ui,
  server = server
)