# Clear workspace
rm(list = ls())

# Load required libraries
library(cec2017)
library(ringbuffer)

# Source the DES implementation
source("DES.R")

# Set seed for reproducibility
set.seed(42)

# Function to run DES on CEC2017 functions
run_des_cec2017 <- function(function_id, dimensions, runs = 10) {
  
  cat(sprintf("Running DES on CEC2017 Function %d, Dimensions: %d\n", function_id, dimensions))
  
  results <- list()
  
  for (run in 1:runs) {
    cat(sprintf("  Run %d/%d\n", run, runs))
    
    # Configure DES with diagnostics enabled
    control_params <- list(
      budget = 10000 * dimensions,        # Function evaluation budget
      lambda = 4 * dimensions,            # Population size
      diag = TRUE,                        # Enable all diagnostics
      diag.bestVal = TRUE,               # Track best fitness over time
      diag.mean = TRUE,                  # Track mean fitness
      diag.Ft = TRUE,                    # Track scaling factor
      diag.value = TRUE,                 # Track all fitness values
      stopfitness = -Inf                 # Don't stop early
    )
    
    # Create wrapper function for CEC2017
    cec_function <- function(x) {
      return(cec2017(function_id, x))
    }
    
    # Run DES optimization
    start_time <- Sys.time()
    result <- DES(
      par = rep(0, dimensions),           # Initial point (center of search space)
      fn = cec_function,
      lower = rep(-100, dimensions),      # CEC2017 standard bounds
      upper = rep(100, dimensions),
      control = control_params
    )
    end_time <- Sys.time()
    
    # Store results
    results[[run]] <- list(
      best_fitness = result$value,
      evaluations = result$counts[["function"]],
      runtime = as.numeric(end_time - start_time, units = "secs"),
      convergence = result$convergence,
      # Diagnostic data
      best_fitness_history = as.vector(result$diagnostic$bestVal),
      mean_fitness_history = as.vector(result$diagnostic$mean),
      Ft_history = as.vector(result$diagnostic$Ft),
      all_fitness_values = result$diagnostic$value
    )
  }
  
  return(results)
}

# Function to calculate statistics from results
calculate_statistics <- function(results) {
  final_fitness <- sapply(results, function(x) x$best_fitness)
  evaluations <- sapply(results, function(x) x$evaluations)
  runtimes <- sapply(results, function(x) x$runtime)
  
  stats <- list(
    best_fitness = list(
      mean = mean(final_fitness),
      median = median(final_fitness),
      std = sd(final_fitness),
      min = min(final_fitness),
      max = max(final_fitness)
    ),
    evaluations = list(
      mean = mean(evaluations),
      median = median(evaluations),
      std = sd(evaluations)
    ),
    runtime = list(
      mean = mean(runtimes),
      median = median(runtimes),
      std = sd(runtimes)
    )
  )
  
  return(stats)
}

# Function to save convergence data for Python comparison
save_convergence_data <- function(results, function_id, dimensions) {
  # Extract convergence curves from all runs
  convergence_data <- list()
  
  for (i in 1:length(results)) {
    convergence_data[[i]] <- list(
      run = i,
      best_fitness_history = results[[i]]$best_fitness_history,
      evaluations = length(results[[i]]$best_fitness_history),
      final_fitness = results[[i]]$best_fitness
    )
  }
  
  # Save as RData file
  filename <- sprintf("r_results_f%d_d%d.RData", function_id, dimensions)
  save(convergence_data, file = filename)
  
  # Also save as CSV for easier Python reading
  # Create a matrix with all convergence curves (pad with NA if needed)
  max_length <- max(sapply(convergence_data, function(x) length(x$best_fitness_history)))
  
  convergence_matrix <- matrix(NA, nrow = max_length, ncol = length(results))
  colnames(convergence_matrix) <- paste0("run_", 1:length(results))
  
  for (i in 1:length(results)) {
    history <- results[[i]]$best_fitness_history
    convergence_matrix[1:length(history), i] <- history
  }
  
  # Save convergence curves as CSV
  csv_filename <- sprintf("r_convergence_f%d_d%d.csv", function_id, dimensions)
  write.csv(convergence_matrix, csv_filename, row.names = FALSE)
  
  # Save summary statistics as CSV
  final_fitness <- sapply(results, function(x) x$best_fitness)
  summary_data <- data.frame(
    run = 1:length(results),
    final_fitness = final_fitness,
    evaluations = sapply(results, function(x) x$evaluations),
    runtime = sapply(results, function(x) x$runtime)
  )
  
  summary_filename <- sprintf("r_summary_f%d_d%d.csv", function_id, dimensions)
  write.csv(summary_data, summary_filename, row.names = FALSE)
  
  cat(sprintf("Saved R results to: %s, %s, %s\n", filename, csv_filename, summary_filename))
}

# Main execution
main <- function() {
  # Test parameters - start simple
  function_id <- 1    # CEC2017 Function 1 (Shifted and Rotated Bent Cigar Function)
  dimensions <- 10    # Start with 10 dimensions
  runs <- 10          # Number of independent runs
  
  cat("=== DES on CEC2017 Comparison Study ===\n")
  cat(sprintf("Function: F%d\n", function_id))
  cat(sprintf("Dimensions: %d\n", dimensions))
  cat(sprintf("Runs: %d\n", runs))
  cat(sprintf("Budget per run: %d\n", 10000 * dimensions))
  cat("=====================================\n\n")
  
  # Test if CEC2017 is working
  cat("Testing CEC2017 function...\n")
  test_point <- rep(1, dimensions)
  test_value <- cec2017(function_id, test_point)
  cat(sprintf("CEC2017 F%d at point [1,1,...,1]: %f\n\n", function_id, test_value))
  
  # Run the comparison
  results <- run_des_cec2017(function_id, dimensions, runs)
  
  # Calculate and display statistics
  stats <- calculate_statistics(results)
  
  cat("\n=== RESULTS SUMMARY ===\n")
  cat(sprintf("Best Fitness - Mean: %.6e, Median: %.6e, Std: %.6e\n", 
              stats$best_fitness$mean, stats$best_fitness$median, stats$best_fitness$std))
  cat(sprintf("Best Fitness - Min: %.6e, Max: %.6e\n", 
              stats$best_fitness$min, stats$best_fitness$max))
  cat(sprintf("Evaluations - Mean: %.0f, Median: %.0f\n", 
              stats$evaluations$mean, stats$evaluations$median))
  cat(sprintf("Runtime - Mean: %.2f sec, Median: %.2f sec\n", 
              stats$runtime$mean, stats$runtime$median))
  
  # Save results for Python comparison
  save_convergence_data(results, function_id, dimensions)
  
  cat("\n=== SUCCESS ===\n")
  cat("R comparison completed successfully!\n")
  cat("Results saved for Python comparison.\n")
  
  return(results)
}

# Run the main function
results <- main()