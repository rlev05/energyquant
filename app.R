library(shiny)
library(bslib)

source("R/config.R")
source("R/database.R")
source("R/market_series.R")
source("R/observation_store.R")
source("R/market_analytics.R")
source("R/risk_analytics.R")
source("R/correlation_analytics.R")
source("R/anomaly_detection.R")
source("R/regime_detection.R")
source("R/forecasting.R")
source("R/data_quality.R")
source("R/dashboard_data.R")
source("R/dashboard_analytics.R")
source("R/dashboard_forecasting.R")
source("R/dashboard_event_studies.R")
source("R/dashboard_data_health.R")

config <- load_config()

connection <- tryCatch(
  connect_database(
    config$database_path
  ),
  error = function(error) {
    NULL
  }
)

if (!is.null(connection)) {
  onStop(
    function() {
      disconnect_database(
        connection
      )
    }
  )
}

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

correlation_matrix <-
  prepare_correlation_dashboard(
    analytics
  )

anomaly_dashboard <-
  prepare_anomaly_dashboard(
    analytics
  )

regime_dashboard <-
  prepare_regime_dashboard(
    analytics
  )

data_health_dashboard <-
  prepare_data_health_dashboard(
    observations =
      dashboard_data$observations,

    expected_series =
      get_market_series()
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
        paste(
          "Live market monitoring, quantitative risk",
          "analytics and cross-market intelligence."
        )
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

      tags$h2(
        "Market Explorer"
      ),

      tags$p(
        paste(
          "Explore historical prices and rolling",
          "volatility across EnergyQuant markets."
        )
      ),

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
  ),

  bslib::nav_panel(
    "Relationships",

    tags$div(
      class = "container-fluid pt-4",

      tags$h2(
        "Cross-Market Relationships"
      ),

      tags$p(
        paste(
          "Analyse full-period and rolling return",
          "correlations across energy, equity",
          "and currency markets."
        )
      ),

      fluidRow(
        column(
          width = 3,

          selectInput(
            inputId = "correlation_first",
            label = "First market",
            choices = series_choices,
            selected = "brent"
          ),

          selectInput(
            inputId = "correlation_second",
            label = "Second market",
            choices = series_choices,
            selected = "wti"
          ),

          sliderInput(
            inputId = "correlation_window",
            label = "Rolling window",
            min = 20,
            max = 120,
            value = 60,
            step = 10
          )
        ),

        column(
          width = 9,

          bslib::card(
            bslib::card_header(
              "Rolling correlation"
            ),

            plotOutput(
              "rolling_correlation_plot",
              height = "380px"
            )
          )
        )
      ),

      tags$br(),

      bslib::card(
        bslib::card_header(
          "Full-period correlation matrix"
        ),

        tableOutput(
          "correlation_table"
        )
      )
    )
  ),

  bslib::nav_panel(
    "Anomalies",

    tags$div(
      class = "container-fluid pt-4",

      tags$h2(
        "Unusual Market Moves"
      ),

      tags$p(
        paste(
          "Rolling z-score detection highlights returns",
          "that are unusual relative to each market's",
          "recent historical behaviour."
        )
      ),

      bslib::card(
        bslib::card_header(
          "Anomaly summary"
        ),

        tableOutput(
          "anomaly_summary"
        )
      ),

      tags$br(),

      fluidRow(
        column(
          width = 3,

          selectInput(
            inputId = "anomaly_market",
            label = "Market",
            choices = series_choices,
            selected = "brent"
          )
        ),

        column(
          width = 9,

          bslib::card(
            bslib::card_header(
              "Return anomaly history"
            ),

            plotOutput(
              "anomaly_plot",
              height = "380px"
            )
          )
        )
      ),

      tags$br(),

      bslib::card(
        bslib::card_header(
          "Most recent anomalies"
        ),

        tableOutput(
          "recent_anomalies"
        )
      )
    )
  ),

  bslib::nav_panel(
    "Regimes",

    tags$div(
      class = "container-fluid pt-4",

      tags$h2(
        "Market Volatility Regimes"
      ),

      tags$p(
        paste(
          "Classify markets into low, normal and",
          "high-volatility environments using",
          "historical rolling thresholds."
        )
      ),

      bslib::card(
        bslib::card_header(
          "Current market regimes"
        ),

        tableOutput(
          "current_regimes"
        )
      ),

      tags$br(),

      fluidRow(
        column(
          width = 3,

          selectInput(
            inputId = "regime_market",
            label = "Market",
            choices = series_choices,
            selected = "brent"
          )
        ),

        column(
          width = 9,

          bslib::card(
            bslib::card_header(
              "Volatility regime history"
            ),

            plotOutput(
              "regime_plot",
              height = "400px"
            )
          )
        )
      ),

      tags$br(),

      bslib::card(
        bslib::card_header(
          "Recent regime transitions"
        ),

        tableOutput(
          "regime_transitions"
        )
      )
    )
  ),

  bslib::nav_panel(
    "Forecasting",

    tags$div(
      class = "container-fluid pt-4",

      tags$h2(
        "Forecasting & Backtesting"
      ),

      tags$p(
        paste(
          "Compare naive, ARIMA and ETS models using",
          "rolling out-of-sample forecasts rather than",
          "in-sample model fit."
        )
      ),

      fluidRow(
        column(
          width = 3,

          selectInput(
            inputId = "forecast_market",
            label = "Market",
            choices = series_choices,
            selected = "brent"
          ),

          sliderInput(
            inputId = "forecast_points",
            label = "Backtest observations",
            min = 10,
            max = 60,
            value = 30,
            step = 10
          ),

          actionButton(
            inputId = "run_forecast",
            label = "Run backtest",
            class = "btn-primary"
          ),

          tags$br(),
          tags$br(),

          tags$p(
            paste(
              "ARIMA and ETS are refitted at each step,",
              "so the analysis may take a short while."
            )
          )
        ),

        column(
          width = 9,

          bslib::card(
            bslib::card_header(
              "Out-of-sample forecasts"
            ),

            plotOutput(
              "forecast_plot",
              height = "400px"
            )
          )
        )
      ),

      tags$br(),

      bslib::card(
        bslib::card_header(
          "Model performance"
        ),

        tableOutput(
          "forecast_performance"
        )
      ),

      tags$br(),

      bslib::card(
        bslib::card_header(
          "Best model"
        ),

        tableOutput(
          "best_forecast_model"
        )
      )
    )
  ),

  bslib::nav_panel(
    "Event Studies",

    tags$div(
      class = "container-fluid pt-4",

      tags$h2(
        "Cross-Market Event Studies"
      ),

      tags$p(
        paste(
          "Measure how energy, equity and currency",
          "markets behave before, during and after",
          "a selected event date."
        )
      ),

      fluidRow(
        column(
          width = 3,

          dateInput(
            inputId = "event_date",
            label = "Event date",
            value = as.Date(
              "2022-02-24"
            ),
            min = minimum_date,
            max = maximum_date
          ),

          sliderInput(
            inputId = "event_pre_window",
            label = "Pre-event observations",
            min = 1,
            max = 20,
            value = 5
          ),

          sliderInput(
            inputId = "event_post_window",
            label = "Post-event observations",
            min = 1,
            max = 20,
            value = 5
          ),

          selectInput(
            inputId = "event_market",
            label = "Market to plot",
            choices = series_choices,
            selected = "brent"
          )
        ),

        column(
          width = 9,

          bslib::card(
            bslib::card_header(
              "Event-window performance"
            ),

            plotOutput(
              "event_study_plot",
              height = "400px"
            )
          )
        )
      ),

      tags$br(),

      bslib::card(
        bslib::card_header(
          "Cross-market event summary"
        ),

        tableOutput(
          "event_study_summary"
        )
      )
    )
  ),

  bslib::nav_panel(
    "Data Health",

    tags$div(
      class = "container-fluid pt-4",

      tags$h2(
        "Data Health & Coverage"
      ),

      tags$p(
        paste(
          "Monitor market coverage, freshness,",
          "duplicate observations and validation",
          "status across EnergyQuant data sources."
        )
      ),

      fluidRow(
        column(
          width = 4,

          bslib::card(
            bslib::card_header(
              "Overall status"
            ),

            tags$h2(
              textOutput(
                "data_health_status",
                inline = TRUE
              )
            )
          )
        ),

        column(
          width = 4,

          bslib::card(
            bslib::card_header(
              "Duplicate observations"
            ),

            tags$h2(
              textOutput(
                "duplicate_count",
                inline = TRUE
              )
            )
          )
        ),

        column(
          width = 4,

          bslib::card(
            bslib::card_header(
              "Invalid observations"
            ),

            tags$h2(
              textOutput(
                "invalid_count",
                inline = TRUE
              )
            )
          )
        )
      ),

      tags$br(),

      bslib::card(
        bslib::card_header(
          "Series health"
        ),

        tableOutput(
          "data_health_table"
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
              rolling_volatility * 100
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
          y = rolling_volatility * 100
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
            annualised_return * 100
          ),

        `Annualised Volatility` =
          sprintf(
            "%.2f%%",
            annualised_volatility * 100
          ),

        `VaR 95%` =
          sprintf(
            "%.2f%%",
            value_at_risk * 100
          ),

        `Expected Shortfall 95%` =
          sprintf(
            "%.2f%%",
            expected_shortfall * 100
          ),

        `Maximum Drawdown` =
          sprintf(
            "%.2f%%",
            maximum_drawdown * 100
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

  output$correlation_table <- renderTable(
  {
    matrix_data <- round(
      correlation_matrix,
      3
    )

    data.frame(
      Market = rownames(
        matrix_data
      ),
      matrix_data,
      row.names = NULL,
      check.names = FALSE
    )
  },

    striped = TRUE,
    hover = TRUE
  )

  selected_correlation_data <- reactive(
  {
    req(
      input$correlation_first,
      input$correlation_second,
      input$correlation_window
    )

    validate(
      need(
        input$correlation_first !=
          input$correlation_second,
        "Choose two different markets."
      )
    )

    calculate_rolling_correlation(
      analytics = analytics,

      first_series =
        input$correlation_first,

      second_series =
        input$correlation_second,

      window =
        input$correlation_window
    ) |>
      dplyr::filter(
        is.finite(
          correlation
        )
      )
  }
  )

  output$rolling_correlation_plot <-
    renderPlot(
    {
      data <- selected_correlation_data()

      req(
        nrow(data) > 0
      )

      ggplot2::ggplot(
        data,
        ggplot2::aes(
          x = date,
          y = correlation
        )
      ) +
        ggplot2::geom_hline(
          yintercept = 0,
          linetype = "dashed"
        ) +
        ggplot2::geom_line(
          linewidth = 0.8
        ) +
        ggplot2::coord_cartesian(
          ylim = c(
            -1,
            1
          )
        ) +
        ggplot2::labs(
          x = NULL,
          y = "Correlation"
        ) +
        ggplot2::theme_minimal(
          base_size = 13
        )
    }
    )

  output$anomaly_summary <- renderTable(
  {
    anomaly_dashboard$summary |>
      dplyr::left_join(
        market_metadata |>
          dplyr::select(
            series_key,
            display_name
          ),
        by = "series_key"
      ) |>
      dplyr::transmute(
        Market = display_name,

        Observations =
          observations,

        Anomalies =
          anomalies,

        Positive =
          positive_anomalies,

        Negative =
          negative_anomalies,

        `Anomaly Rate` =
          sprintf(
            "%.2f%%",
            anomaly_rate * 100
          ),

        `Largest |Z|` =
          round(
            largest_absolute_z,
            2
          ),

        `Latest Anomaly` =
          latest_anomaly_date
      )
  },

    striped = TRUE,
    hover = TRUE
  )

  selected_anomaly_data <- reactive(
  {
    req(
      input$anomaly_market
    )

    anomaly_dashboard$results |>
      dplyr::filter(
        series_key ==
          input$anomaly_market,

        !is.na(
          simple_return
        )
      )
  }
  )

  output$anomaly_plot <- renderPlot(
  {
    data <- selected_anomaly_data()

    req(
      nrow(data) > 0
    )

    ggplot2::ggplot(
      data,
      ggplot2::aes(
        x = date,
        y = simple_return * 100
      )
    ) +
      ggplot2::geom_hline(
        yintercept = 0,
        linetype = "dashed"
      ) +
      ggplot2::geom_line(
        linewidth = 0.6
      ) +
      ggplot2::geom_point(
        data = data |>
          dplyr::filter(
            is_anomaly
          ),
        size = 2.5
      ) +
      ggplot2::labs(
        x = NULL,
        y = "Daily return (%)"
      ) +
      ggplot2::theme_minimal(
        base_size = 13
      )
  }
  )

  output$recent_anomalies <- renderTable(
  {
    anomaly_dashboard$results |>
      dplyr::filter(
        is_anomaly
      ) |>
      dplyr::left_join(
        market_metadata |>
          dplyr::select(
            series_key,
            display_name
          ),
        by = "series_key"
      ) |>
      dplyr::arrange(
        dplyr::desc(
          date
        )
      ) |>
      dplyr::slice_head(
        n = 15
      ) |>
      dplyr::transmute(
        Market = display_name,

        Date = date,

        Return =
          sprintf(
            "%.2f%%",
            simple_return * 100
          ),

        `Z Score` =
          round(
            anomaly_z_score,
            2
          ),

        Direction =
          anomaly_direction
      )
  },

    striped = TRUE,
    hover = TRUE
  )

  output$current_regimes <- renderTable(
  {
    regime_dashboard$current |>
      dplyr::left_join(
        market_metadata |>
          dplyr::select(
            series_key,
            display_name
          ),
        by = "series_key"
      ) |>
      dplyr::transmute(
        Market = display_name,

        Date = date,

        Regime = regime,

        `Current Volatility` =
          sprintf(
            "%.2f%%",
            rolling_volatility * 100
          ),

        `Low Threshold` =
          sprintf(
            "%.2f%%",
            regime_lower_threshold * 100
          ),

        `High Threshold` =
          sprintf(
            "%.2f%%",
            regime_upper_threshold * 100
          )
      )
  },

    striped = TRUE,
    hover = TRUE
  )

  selected_regime_data <- reactive(
  {
    req(
      input$regime_market
    )

    regime_dashboard$results |>
      dplyr::filter(
        series_key ==
          input$regime_market,

        !is.na(
          regime
        )
      )
  }
  )

  output$regime_plot <- renderPlot(
  {
    data <- selected_regime_data()

    req(
      nrow(data) > 0
    )

    ggplot2::ggplot(
      data,
      ggplot2::aes(
        x = date
      )
    ) +
      ggplot2::geom_line(
        ggplot2::aes(
          y =
            rolling_volatility * 100
        ),
        linewidth = 0.8
      ) +
      ggplot2::geom_line(
        ggplot2::aes(
          y =
            regime_lower_threshold * 100
        ),
        linetype = "dashed"
      ) +
      ggplot2::geom_line(
        ggplot2::aes(
          y =
            regime_upper_threshold * 100
        ),
        linetype = "dashed"
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

  output$regime_transitions <- renderTable(
  {
    regime_dashboard$transitions |>
      dplyr::left_join(
        market_metadata |>
          dplyr::select(
            series_key,
            display_name
          ),
        by = "series_key"
      ) |>
      dplyr::arrange(
        dplyr::desc(
          date
        )
      ) |>
      dplyr::slice_head(
        n = 15
      ) |>
      dplyr::transmute(
        Market = display_name,

        Date = date,

        From =
          previous_regime,

        To =
          regime,

        Volatility =
          sprintf(
            "%.2f%%",
            rolling_volatility * 100
          )
      )
  },

    striped = TRUE,
    hover = TRUE
  )

  forecast_dashboard <- eventReactive(
    input$run_forecast,
  {
    req(
      input$forecast_market,
      input$forecast_points
    )

    withProgress(
      message = "Running forecast backtest",
      value = 0,
    {
      incProgress(
        0.2,
        detail = "Preparing market history..."
      )

      result <- run_dashboard_backtest(
        observations =
          dashboard_data$observations,

        series_key =
          input$forecast_market,

        evaluation_points =
          input$forecast_points,

        training_window = 500,

        minimum_training = 120
      )

      incProgress(
        0.8,
        detail = "Comparing models..."
      )

      result
    }
    )
  },

    ignoreInit = TRUE
  )

  output$forecast_plot <- renderPlot(
  {
    forecast_data <-
      forecast_dashboard()$results

    req(
      nrow(
        forecast_data
      ) > 0
    )

    plot_data <- forecast_data |>
      dplyr::select(
        date,
        model,
        actual,
        forecast
      )

    actual_data <- plot_data |>
      dplyr::distinct(
        date,
        actual
      )

    ggplot2::ggplot() +
      ggplot2::geom_line(
        data = actual_data,

        ggplot2::aes(
          x = date,
          y = actual
        ),

        linewidth = 1
      ) +
      ggplot2::geom_line(
        data = plot_data,

        ggplot2::aes(
          x = date,
          y = forecast,
          linetype = model
        ),

        linewidth = 0.8
      ) +
      ggplot2::labs(
        x = NULL,
        y = "Market value",
        linetype = "Model"
      ) +
      ggplot2::theme_minimal(
        base_size = 13
      )
  }
  )

  output$forecast_performance <- renderTable(
  {
    forecast_dashboard()$performance |>
      dplyr::arrange(
        rmse
      ) |>
      dplyr::transmute(
        Model = model,

        Forecasts =
          forecasts,

        MAE = round(
          mae,
          3
        ),

        RMSE = round(
          rmse,
          3
        ),

        sMAPE = sprintf(
          "%.2f%%",
          smape * 100
        ),

        Bias = round(
          bias,
          3
        ),

        `Directional Accuracy` =
          sprintf(
            "%.1f%%",
            directional_accuracy * 100
          ),

        `RMSE Rank` =
          rmse_rank
      )
  },

    striped = TRUE,
    hover = TRUE
  )

  output$best_forecast_model <- renderTable(
  {
    forecast_dashboard()$best_model |>
      dplyr::transmute(
        Model = model,

        RMSE = round(
          rmse,
          3
        ),

        MAE = round(
          mae,
          3
        ),

        `Directional Accuracy` =
          sprintf(
            "%.1f%%",
            directional_accuracy * 100
          )
      )
  },

    striped = TRUE,
    hover = TRUE
  )

  event_study_dashboard <- reactive(
  {
    req(
      input$event_date,
      input$event_pre_window,
      input$event_post_window
    )

    prepare_cross_market_event_study(
      analytics = analytics,

      event_date =
        input$event_date,

      pre_window =
        input$event_pre_window,

      post_window =
        input$event_post_window
    )
  }
  )

  selected_event_study <- reactive(
  {
    req(
      input$event_market,
      input$event_date,
      input$event_pre_window,
      input$event_post_window
    )

    prepare_single_event_study(
      analytics = analytics,

      series_key =
        input$event_market,

      event_date =
        input$event_date,

      pre_window =
        input$event_pre_window,

      post_window =
        input$event_post_window
    )
  }
  )

  output$event_study_plot <- renderPlot(
  {
    data <- selected_event_study()

    req(
      nrow(data) > 0
    )

    ggplot2::ggplot(
      data,
      ggplot2::aes(
        x = event_day,
        y =
          cumulative_event_return *
            100
      )
    ) +
      ggplot2::geom_hline(
        yintercept = 0,
        linetype = "dashed"
      ) +
      ggplot2::geom_vline(
        xintercept = 0,
        linetype = "dashed"
      ) +
      ggplot2::geom_line(
        linewidth = 0.9
      ) +
      ggplot2::geom_point(
        size = 2
      ) +
      ggplot2::labs(
        x = "Observations relative to event",
        y = "Cumulative return (%)"
      ) +
      ggplot2::theme_minimal(
        base_size = 13
      )
  }
  )

  output$event_study_summary <- renderTable(
  {
    event_study_dashboard()$summary |>
      dplyr::left_join(
        market_metadata |>
          dplyr::select(
            series_key,
            display_name
          ),
        by = "series_key"
      ) |>
      dplyr::transmute(
        Market =
          display_name,

        `Market Event Date` =
          event_date,

        `Pre-Event Return` =
          sprintf(
            "%.2f%%",
            pre_event_return * 100
          ),

        `Event-Day Return` =
          sprintf(
            "%.2f%%",
            event_day_return * 100
          ),

        `Post-Event Return` =
          sprintf(
            "%.2f%%",
            post_event_return * 100
          ),

        `Total Window Return` =
          sprintf(
            "%.2f%%",
            total_window_return * 100
          )
      )
  },

    striped = TRUE,
    hover = TRUE
  )

  output$data_health_status <- renderText(
  {
    data_health_dashboard$overall_status
  }
  )

  output$duplicate_count <- renderText(
  {
    nrow(
      data_health_dashboard$duplicates
    )
  }
  )

  output$invalid_count <- renderText(
  {
    nrow(
      data_health_dashboard$invalid
    )
  }
  )

  output$data_health_table <- renderTable(
  {
    data_health_dashboard$summary |>
      dplyr::transmute(
        Market =
          display_name,

        Source =
          toupper(
            source
          ),

        Rows =
          rows,

        `First Date` =
          first_date,

        `Latest Date` =
          latest_date,

        `Days Since Latest` =
          days_since_latest,

        Missing =
          missing_values,

        `Non-Finite` =
          non_finite_values,

        Duplicates =
          duplicate_dates,

        Stale =
          ifelse(
            stale,
            "Yes",
            "No"
          ),

        Status =
          status
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