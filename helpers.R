library('ggplot2')
library('gridExtra')
library('data.table')

# Load in the relevant data
IC_adm_data <- fread('data/IC_NL.csv')
scen_output <- as.data.table(readRDS(file = 'data/scen_output.rds'))
scen_description <- as.data.table(readRDS(file = 'data/scen_description.rds'))

#' Creates the Key Parameter UI Interface
#' 
#' @param strategies Character vector indicating which strategy interface to show
#' @param names Character vector giving the actual names of the strategies
#' @returns A tagList which renders the UI
create_exit_parameters <- function(strategies, names) {
  
  res <- tagList()
  n <- length(strategies)
  
  for (i in seq(n)) {
    res[[i]] <- tagList()
    name <- names[i]
    res[[i]][[1]] <- h3(name)
    
    
    if (name == 'Radical Opening') {
      
      res[[i]][[2]] <- p('Radical Opening does not have any parameters.')
      
    } else if (name == 'Phased Lift of Control') {
      
      res[[i]][[2]] <- checkboxGroupInput(
        'phased_opening_phases',
        'Number of Phases',
        inline = FALSE,
        choices = c(
          '10 Phases' = '10',
          '20 Phases' = '20'
        ), selected = '20'
      )
      
      res[[i]][[3]] <- checkboxGroupInput(
        'phased_opening_interval',
        'Interval Size in Days',
        inline = FALSE,
        choices = c(
          '30 Days' = '30',
          '45 Days' = '45',
          '60 Days' = '60'
        ), selected = '45'
      )
      
      res[[i]][[4]] <- checkboxGroupInput(
        'phased_opening_transmission_control',
        'Transmission During Control Reduced to',
        inline = FALSE,
        choices = c(
          '20%' = '20',
          '25%' = '25',
          '30%' = '30'
        ), selected = '25'
      )
      
      res[[i]][[5]] <- checkboxGroupInput(
        'phased_opening_transmission_lift',
        'Interregional Transmission During Lift Reduced to',
        inline = FALSE,
        choices = c(
          '0%' = '0',
          '50%' = '50',
          '100% (No Reduction)' = '100',
          '125% (Increase)' = '125'
        ), selected = '50'
      )
      
      res[[i]][[6]] <- checkboxGroupInput(
        'phased_opening_prespecified',
        'Pre-specified Type of Phased Lift of Control',
        inline = FALSE,
        choices = c(
          'Standard' = 'scenario-1',
          'Efficient' = 'scenario-2',
          'Optimistic' = 'scenario-3'
        ), selected = NULL
      )
      
      
    } else if (name == 'Flattening the Curve') {
      
      res[[i]][[2]] <- checkboxGroupInput(
        'flattening-curve',
        # 'exit_flattening_curve',
        'Type of Flattening the Curve',
        inline = FALSE,
        choices = c(
          'Transmission Reduced to 30%' = 'scenario-1',
          'Transmission Reduced to 35%' = 'scenario-2',
          'Transmission Reduced to 40%' = 'scenario-3',
          'Transmission Reduced to 35% + Release Last Intervention Early' = 'scenario-4',
          'Transmission Reduced to 35% + Skip Last Intervention' = 'scenario-5'
        ), selected = 'scenario-1'
      )
      
    } else if (name == 'Contact Tracing') {
      
      res[[i]][[2]] <- checkboxGroupInput(
        'contact_tracing_lockdown',
        'Additional Lockdown for:',
        inline = FALSE,
        choices = c(
          '0 Days' = '0 Days',
          '100 Days' = '100 Days'
        ), selected = '0 Days'
      )
        
        res[[i]][[3]] <- checkboxGroupInput(
          'contact_tracing_trace_probability',
          '% of Exposed but not yet Infectious Contacts Successfully Traced:',
          inline = FALSE,
          choices = c(
            '90%' = '90%',
            '80%' = '80%',
            '70%' = '70%',
            '60%' = '60%',
            '50%' = '50%',
            '40%' = '40%',
            '30%' = '30%',
            '20%' = '20%',
            '10%' = '10%'
          ), selected = '90%'
        )
        
        res[[i]][[4]] <- checkboxGroupInput(
          'contact_tracing_contact_reduction',
          '% Reduction in Contacts for Exposed and Infectious People:',
          inline = FALSE,
          choices = c(
            '90%' = '90%',
            '80%' = '80%',
            '70%' = '70%',
            '60%' = '60%',
            '50%' = '50%'
          ), selected = '90%'
        )
        
        res[[i]][[5]] <- checkboxGroupInput(
          'contact_tracing_tracing_delay',
          'Delay in Contact Tracing of Infectious People:',
          inline = FALSE,
          choices = c(
            '2 Days' = '2 days',
            '3 Days' = '3 days',
            '4 Days' = '4 days',
            '5 Days' = '5 days'
          ), selected = '2 days'
        )
        
    } else if (name == 'Intermittent Lockdown') {
      
      res[[i]][[2]] <- checkboxGroupInput(
        'intermittent-lockdown',
        # 'exit_intermittent_lockdown',
        'Type of Intermittent Lockdown',
        inline = FALSE,
        choices = c(
          'Perfectly executed' = 'scenario-1',
          'Lockdown too light' = 'scenario-2',
          'Release too long' = 'scenario-3'
        ), selected = 'scenario-1'
      )
      
    }
  }
  
  res
}


#' Visualizes the Exit Strategies
#' 
#' @param strategies Character vector indicating which strategy interface to show
#' @param input List giving the user inputs
#' @param scen_output data.table giving the scenario / exit-strategy data base
#' @param scen_description data.table giving the scenario / exit-strategy descriptions
#' @param IC_adm_data data.table giving the IC data
#' @returns ggplot object
visualize_exit_strategy <- function(
  strategies, input, scen_output, scen_description, IC_adm_data, ...
  ) {
  
  map <- list(
    'radical-opening' = 'Instant lift of control',
    
    'flattening-curve' = list(
      'scenario-1' = 'FtC: 3 years, transmission at 30%-55%-90%',
      'scenario-2' = 'FtC: 3 years, transmission at 35%-55%-90%',
      'scenario-3' = 'FtC: 3 years, transmission at 40%-55%-90%',
      'scenario-4' = 'FtC: 2.5 years, transmission at 35%-55%-90%',
      'scenario-5' = 'FtC: 2 years, transmission at 35%-55%'
    ),
    
    'phased-opening' = list(
      'scenario-1' = 'Phased lift of control (standard)',
      'scenario-2' = 'Phased lift of control (efficient)',
      'scenario-3' = 'Phased lift of control (optimistic)'
    ),
    
    'intermittent-lockdown' = list(
      'scenario-1' = 'Intermittent lockdown (perfectly executed)',
      'scenario-2' = 'Intermittent lockdown (lockdown too light)',
      'scenario-3' = 'Intermittent lockdown (release too long)'
    )
  )
  
  j <- 1
  sel <- c()
  parset <- c()
  
  for (strategy in strategies) {
    # s <- paste0('exit_', gsub('-', '_', strategy))
    s <- strategy
    
    # Radical opening has no parameterization
    if (strategy == 'radical-opening') {
      sel <- c(sel, map[[strategy]])
      
    } else if (strategy == 'contact-tracing') {
      # Contact Tracing requires additional logic
      
      additional_lockdown <- input$contact_tracing_lockdown
      trace_prob_E <- input$contact_tracing_trace_probability
      trace_delay_I <- input$contact_tracing_tracing_delay
      trace_contact_reduction <- input$contact_tracing_contact_reduction
      
      all_boxes_checked <- (!is.null(additional_lockdown) && !is.null(trace_prob_E) &&
                            !is.null(trace_delay_I) && !is.null(trace_contact_reduction))
      
      if (all_boxes_checked) {
        combinations <- expand.grid(
          'lockdown' = additional_lockdown,
          'prob' = trace_prob_E,
          'delay' = trace_delay_I,
          'reduction' = trace_contact_reduction
        )
        
        for (i in seq(nrow(combinations))) {
          comb <- combinations[i, ]
          # print(comb)
          
          if (comb$lockdown == '0 Days') {
            s <- paste0('TTI (', 'prob_E = ', comb$prob, ', ',
                                 'delay_I = ', comb$delay, ', ',
                                 'effect = ', comb$reduction, ')')
          } else {
            s <- paste0('Extend + TTI (', 'prob_E = ', comb$prob, ', ',
                                          'delay_I = ', comb$delay, ', ',
                                          'effect = ', comb$reduction, ')')
          }
          
          sel <- c(sel, s)
        }
      }
    } else if (strategy == 'phased-opening') {
      # Phased Lift of Control requires additional logic
      
      phases <- input$phased_opening_phases
      interval <- input$phased_opening_interval
      transmission_control <- input$phased_opening_transmission_control
      transmission_lift <- input$phased_opening_transmission_lift
      prespecified <- input$phased_opening_prespecified
      
      all_boxes_checked <- (!is.null(phases) && !is.null(interval) &&
                            !is.null(transmission_control) && !is.null(transmission_lift))
      
      # Add all prespecified ones
      if (!is.null(prespecified)) {
        for (j in prespecified) {
          sel <- c(sel, map[['phased-opening']][[j]])
        }
      }
      
      if (all_boxes_checked) {
        combinations <- expand.grid(
          'phases' = phases,
          'interval' = interval,
          'transmission_control' = transmission_control,
          'transmission_lift' = transmission_lift
        )
        
        # Filter Phased Lift of Control according to parset, because scen_label is not unambiguous
        for (i in seq(nrow(combinations))) {
          comb <- combinations[i, ]
          
          selected <- scen_description[(phases == comb$phases &
                                        interval == comb$interval &
                                        effect_control == comb$transmission_control &
                                        effect_isolation == comb$transmission_lift)]$par_set
          
          parset <- c(parset, selected)
        }
      }
      
      } else {
        inp <- input[[s]]
          
        if (!is.null(inp)) {
          for (j in inp) {
            sel <- c(sel, map[[strategy]][[j]])
          }
        }
      }
    }
  
  # Do not show a plot if no parameterization is chosen and
  # the strategy is not radical opening (which has no different parameterizations)
  if (length(sel) == 0 && length(parset) == 0) {
    return(NULL)
  }
  
  # print(sel)
  pars <- scen_description[scen_label %in% sel]$par_set
  pars <- c(pars, parset)
  # print(pars)
  
  plot_scen(
    scen_output[par_set %in% pars],
    IC_adm_data = IC_adm_data,
    legend_ratio = ifelse(length(pars) == 1, 0, 0.60),
    ...
  )
}


# Function definitions ---------------------------------------------------------
plot_scen <- function(sim_output,
                      sim_descript = copy(scen_description),
                      IC_adm_data = NULL,
                      ncol = 1,
                      max_I = 6e3,
                      max_IC_prev = 1900 / 17.4,
                      target_R = 60,
                      plot_IC_data = TRUE,
                      x_breaks = NULL,
                      y_breaks_I = NULL,
                      y_breaks_IC_inc = NULL,
                      y_breaks_IC_prev = NULL,
                      y_breaks_R = NULL,
                      x_range = NULL,
                      y_range_I = NULL,
                      y_range_IC_inc = NULL,
                      y_range_IC_prev = NULL,
                      y_range_R = NULL,
                      n_ticks_y = 5,
                      n_ticks_x = 8,
                      intervention_linetype = 3,
                      theme_choice = theme_classic(),
                      scale_margin = 6,
                      legend = "outside",  # or "inside"
                      legend_ratio = .50) {
  
  if (!any(legend %in% c("inside", "outside"))) {
    "legend must be 'inside' or 'outside'"
  }
  
  sim_output <- copy(sim_output)
  index <- sim_output[, unique(par_set)]
  sim_descript <- sim_descript[par_set %in% index]
  
  # Prep axes ----
  intervention_times <- sim_descript[, intervention_t[[1]][-1]]
  
  if (!is.null(x_range)) {
    x_range_temp <- x_range + diff(c(x_range)) / 15 * c(-1, 1)
    sim_output <- sim_output[time %between% x_range_temp]
    intervention_times <- intervention_times[intervention_times %between% x_range_temp]
  }
  
  if (is.null(x_breaks)) {
    x_breaks <- sim_output[, pretty(c(time, intervention_times,x_range),
                                    n = n_ticks_x)]  
  } else {
    x_breaks <- x_breaks * -1e3:1e3
  }
  
  x_axis_definition <- scale_x_continuous(name = "\nTime since start of strategy (days)",
                                          breaks = x_breaks)
  
  if (is.null(y_breaks_I)) {
    if (is.null(y_range_I)) {
      y_breaks_I <- sim_output[, pretty(c(0,
                                          I / (S + E + I + R) * 1e6,
                                          max_I), n = n_ticks_y)]
      y_range_I <- range(y_breaks_I)
    } else {
      y_breaks_I <- pretty(y_range_I, n = n_ticks_y)
    }
  } else {
    y_breaks_I <- y_breaks_I * 0:1e3
  }
  
  if (is.null(y_breaks_IC_inc)) {
    if (is.null(y_range_IC_inc)) {
      y_breaks_IC_inc <- sim_output[, pretty(c(0,
                                               IC_inc / (S + E + I + R) * 1e6),
                                             n = n_ticks_y)]
      y_range_IC_inc <- range(y_breaks_IC_inc)
    } else {
      y_breaks_IC_inc <- pretty(y_range_IC_inc, n = n_ticks_y)
    }
  } else {
    y_breaks_IC_inc <- y_breaks_IC_inc * 0:1e3
  }
  
  if (is.null(y_breaks_IC_prev)) {
    if (is.null(y_range_IC_prev)) {
      y_breaks_IC_prev <- sim_output[, pretty(c(0,
                                                IC_prev / (S + E + I + R) * 1e6,
                                                max_IC_prev), n = n_ticks_y)]
      y_range_IC_prev <- range(y_breaks_IC_prev)
    } else {
      y_breaks_IC_prev <- pretty(y_range_IC_prev, n = n_ticks_y)
    }
  } else {
    y_breaks_IC_prev <- y_breaks_IC_prev * 0:1e3
  }
  
  if (is.null(y_breaks_R)) {
    if (is.null(y_range_R)) {
      y_breaks_R <- sim_output[, pretty(c(0,
                                          R / (S + E + I + R) * 100,
                                          target_R), n = n_ticks_y)]
      y_range_R <- range(y_breaks_R)
    } else {
      y_breaks_R <- pretty(y_range_R, n = n_ticks_y)
    }
  } else {
    y_breaks_R <- y_breaks_R * 0:1e3
  }
  
  theme_choice <- theme_choice + theme(axis.title = element_blank())
  
  # Prep data ----
  sim_output[, N_pop := S + E + I + R]
  sim_output <- sim_output[, lapply(.SD, function(x) x / N_pop * 1e6),
                           .SDcols = c("S", "E", "I", "R", "inc", "IC_prev", "IC_inc"),
                           by = .(seed, time, par_set)]
  sim_output[sim_descript,
             on = "par_set",
             scen_label := scen_legend]
  
  # Construct panel A ----
  if (sim_output[, length(unique(par_set)) > 1]) {
    panel_A <- ggplot(data = sim_output,
                      mapping = aes(x = time, y = I,
                                    group = interaction(seed, scen_label),
                                    col = factor(scen_label))) +
      scale_color_discrete(name = NULL,
                           guide = guide_legend(override.aes = list(size = .75))) +
      theme_choice
    
    if (legend == "inside") {
      panel_A <- panel_A +
        theme(legend.title = element_blank(),
              legend.position = c(1, 1),
              legend.justification = c(1, 1),
              legend.background = element_rect(colour = "transparent",
                                               fill = scales::alpha('white', 0.25)))  
    }
    if (legend == "outside") {
      panel_A <- panel_A +
        theme(legend.title = element_blank(),
              legend.position = c(0.05, 1),
              legend.justification = c(0, 1))  
    }
    
  } else {
    panel_A <-ggplot(data = sim_output,
                     mapping = aes(x = time, y = I, group = seed)) +
      theme_choice
  }
  
  if (any(!is.na(intervention_times))) {
    panel_A <- panel_A +
      geom_vline(xintercept = intervention_times,
                 col = "darkgrey", linetype = intervention_linetype)
  }
  
  panel_A <- panel_A +
    geom_hline(yintercept = max_I, linetype = 2) +
    geom_line(size = .2) +
    x_axis_definition + 
    scale_y_continuous(name = NULL,
                       breaks = y_breaks_I,
                       labels = scales::comma) +
    coord_cartesian(x = x_range, y = y_range_I) +
    labs(title = "Number of infectious cases per million")
  
  # Construct panel B ----
  panel_B <-
    if (sim_output[, length(unique(par_set)) > 1]) {
      ggplot(data = sim_output,
             mapping = aes(x = time, y = IC_inc,
                           group = interaction(seed, scen_label),
                           col = factor(scen_label))) +
        scale_color_discrete(guide = FALSE)
    } else {
      ggplot(data = sim_output,
             mapping = aes(x = time, y = IC_inc, group = seed))
    }
  panel_B <- panel_B + theme_choice
  
  if (any(!is.na(intervention_times))) {
    panel_B <- panel_B +
      geom_vline(xintercept = intervention_times,
                 col = "darkgrey", linetype = intervention_linetype)
  }
  
  panel_B <- panel_B +
    geom_line(size = .2) +
    x_axis_definition + 
    scale_y_continuous(name = NULL,
                       breaks = y_breaks_IC_inc,
                       labels = scales::comma) + 
    coord_cartesian(x = x_range, y = y_range_IC_inc) +
    labs(title = "Number of new cases in IC per million per day")
  
  if (plot_IC_data) {
    panel_B <- panel_B +
      geom_point(data = IC_adm_data,
                 mapping = aes(x = Day_since_lockdown + intervention_times[1],
                               y = NICE_new / 17.4,
                               group = NULL),
                 size = 0.8, col = "red", alpha = .75, shape = 1)
  }
  
  # Construct panel C ----
  panel_C <-
    if (sim_output[, length(unique(par_set)) > 1]) {
      ggplot(data = sim_output,
             mapping = aes(x = time, y = IC_prev,
                           group = interaction(seed, scen_label),
                           col = factor(scen_label))) +
        scale_color_discrete(guide = FALSE)
    } else {
      ggplot(data = sim_output,
             mapping = aes(x = time, y = IC_prev, group = seed))
    }
  panel_C <- panel_C + theme_choice
  
  if (any(!is.na(intervention_times))) {
    panel_C <- panel_C +
      geom_vline(xintercept = intervention_times,
                 col = "darkgrey", linetype = intervention_linetype)
  }
  
  panel_C <- panel_C +
    geom_hline(yintercept = max_IC_prev, linetype = 2) +
    geom_line(size = .2) +
    x_axis_definition + 
    scale_y_continuous(name = NULL,
                       breaks = y_breaks_IC_prev,
                       labels = scales::comma) + 
    coord_cartesian(x = x_range, y = y_range_IC_prev) +
    labs(title = "Number of cases present in IC per million")
  
  if (plot_IC_data) {
    panel_C <- panel_C +
      geom_point(data = IC_adm_data,
                 mapping = aes(x = Day_since_lockdown + intervention_times[1],
                               y = NICE / 17.4,
                               group = NULL),
                 size = 0.8, col = "red", alpha = .75, shape = 1)
  }
  
  # Construct panel D: Recovered ----
  panel_D <-
    if (sim_output[, length(unique(par_set)) > 1]) {
      ggplot(data = sim_output,
             mapping = aes(x = time,
                           y = 100 * R / (S + E + I + R),
                           group = interaction(seed, scen_label),
                           col = factor(scen_label))) +
        scale_color_discrete(guide = FALSE)
    } else {
      ggplot(data = sim_output,
             mapping = aes(x = time,
                           y = 100 * R / (S + E + I + R),
                           group = seed))  
    }
  panel_D <- panel_D + theme_choice
  
  if (any(!is.na(intervention_times))) {
    panel_D <- panel_D +
      geom_vline(xintercept = intervention_times,
                 col = "darkgrey", linetype = intervention_linetype)
  }
  
  panel_D <- panel_D +
    geom_hline(yintercept = target_R, linetype = 2) +
    geom_line(size = .2) +
    x_axis_definition + 
    scale_y_continuous(name = NULL,
                       breaks = y_breaks_R) +
    coord_cartesian(x = x_range, y = y_range_R) +
    labs(title = "Percentage recovered (%)")
  
  # Manage legend
  get_legend <- function(a.gplot) {
    tmp <- ggplot_gtable(ggplot_build(a.gplot))
    leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
    legend <- tmp$grobs[[leg]]
    return(legend)
  }
  
  if (sim_output[, length(unique(par_set)) > 1] & legend == "outside") {
    mylegend <- get_legend(panel_A)
    panel_A <- panel_A + theme(legend.position = "none")
  } else {
    mylegend <- grid::grid.rect(gp = grid::gpar(col = "white"))
  }
  
  # Construct compound plot ----
  if (ncol == 1) {
    margin_A <- theme(plot.margin = unit(rep(6, 4) + scale_margin * c(1, rep(0, 3)), "pt"))
    margin_B <- theme(plot.margin = unit(rep(6, 4) + scale_margin * c(.5, 0, .5, 0), "pt"))
    margin_C <- theme(plot.margin = unit(rep(6, 4) + scale_margin * c(.5, 0, .5, 0), "pt"))
    margin_D <- theme(plot.margin = unit(rep(6, 4) + scale_margin * c(0, 0, 1, 0), "pt"))
  } else {
    margin_A <- theme(plot.margin = unit(rep(6, 4) + scale_margin * rep(1, 4), "pt"))
    margin_B <- theme(plot.margin = unit(rep(6, 4) + scale_margin * rep(1, 4), "pt"))
    margin_C <- theme(plot.margin = unit(rep(6, 4) + scale_margin * rep(1, 4), "pt"))
    margin_D <- theme(plot.margin = unit(rep(6, 4) + scale_margin * rep(1, 4), "pt"))
  }
  
  gA <- ggplotGrob(panel_A + margin_A)
  gB <- ggplotGrob(panel_B + margin_B)
  gC <- ggplotGrob(panel_C + margin_C)
  gD <- ggplotGrob(panel_D + margin_D)
  
  maxWidth = grid::unit.pmax(gA$widths[2:5],
                             gB$widths[2:5],
                             gC$widths[2:5],
                             gD$widths[2:5])
  gA$widths[2:5] <- as.list(maxWidth)
  gB$widths[2:5] <- as.list(maxWidth)
  gC$widths[2:5] <- as.list(maxWidth)
  gD$widths[2:5] <- as.list(maxWidth)
  
  # if (sim_output[, length(unique(par_set)) > 1] & legend == "outside") {
  #   grid.arrange(mylegend,
  #                gA, gB, gC, gD,
  #                bottom = "Time since start of strategy (days)",
  #                ncol = 1,
  #                heights = c(1, rep(4, 4)))
  # } else {
  #   grid.arrange(gA, gB, gC, gD,
  #                ncol = ncol,
  #                bottom = "Time since start of strategy (days)")
  # }
  
  grid.arrange(mylegend,
               gA, gB, gC, gD,
               bottom = "Time since start of strategy (days)",
               ncol = 1,
               heights = c(legend_ratio, rep(1, 4)))
  
}