library(Biostrings)
library(tidyverse)
library(data.table)
library(rentrez)
library(parallel)

results <- fread("~/Documents/species_id/results/24TGPJ/blast_fastq_sample_1000_reads.txt")

cols <- c("qseqid", "sseqid", "pident", "length", "mismatch", "gapopen", 
          "qstart", "qend", "sstart", "send", "evalue", "bitscore", 
          "sskingdoms", "ssciname")
names(results) <- cols
results <- results[,-c(13:14)]


df <- results

unique_accs <- unique(df$sseqid)

get_species_from_ncbi <- function(acc) {
  # Attempt to get the NCBI summary
  summary_info <- tryCatch(
    entrez_summary(db = "nuccore", id = acc),
    error = function(e) NULL
  )
  
  if (is.null(summary_info)) {
    return(NA)  # Return NA if no info found
  } else {
    return(summary_info$organism)  # 'organism' field has the species name
  }
}

species_names <- sapply(unique_accs, get_species_from_ncbi)


species_df <- data.frame(
  sseqid = unique_accs,
  species = species_names,
  stringsAsFactors = FALSE
)

# Merge on the sseqid column
df_with_species <- merge(df, species_df, by = "sseqid", all.x = TRUE)

df_best <- df_with_species %>%
  group_by(qseqid, species) %>%
  slice_max(bitscore, n = 1, with_ties = FALSE) %>%
  ungroup()


# Arrange each qseqid's hits by descending bitscore and assign a rank
df_ranked <- df_best %>%
  group_by(qseqid) %>%
  arrange(desc(bitscore), .by_group = TRUE) %>%
  mutate(rank = row_number()) %>%
  ungroup()

# Create a list of ballots, one per qseqid, where each ballot is an ordered vector of species
ballots <- df_ranked %>%
  group_by(qseqid) %>%
  summarise(ballot = list(species)) %>%
  pull(ballot)


irv <- function(ballots) {
  remaining <- unique(unlist(ballots))
  iteration <- 1
  
  while (TRUE) {
    # For each ballot, take the highest-ranked candidate that is still remaining
    votes <- sapply(ballots, function(ballot) {
      candidate <- ballot[ballot %in% remaining]
      if (length(candidate) > 0) candidate[1] else NA
    })
    
    counts <- table(votes)
    total <- sum(counts)
    
    # Check if any candidate has a majority (>50% of votes)
    if (any(counts > total / 2)) {
      winner <- names(which(counts > total / 2))
      if (iteration == 1) {
        percent <- (counts[winner] / total) * 100
        return(list(winner = winner, iteration = iteration, percentage = percent))
      } else {
        return(list(winner = winner, iteration = iteration))
      }
    }
    
    # Eliminate candidate(s) with the fewest votes.
    min_votes <- min(counts)
    eliminated <- names(counts)[counts == min_votes]
    remaining <- setdiff(remaining, eliminated)
    
    # If only one candidate remains, return it.
    if (length(remaining) == 1) {
      return(list(winner = remaining, iteration = iteration))
    }
    # If no candidates remain (all tied), return NA.
    if (length(remaining) == 0) {
      return(list(winner = NA, iteration = iteration))
    }
    
    iteration <- iteration + 1
  }
}

winner_irv <- irv(ballots)
if (!is.null(winner_irv$percentage)) {
  print(paste("IRV winner:", winner_irv$winner, "won in iteration", winner_irv$iteration,
              "with", round(winner_irv$percentage, 2), "% of first-round votes"))
} else {
  print(paste("IRV winner:", winner_irv$winner, "won in iteration", winner_irv$iteration))
}



# Compute Borda scores for each species
scores <- list()
for (ballot in ballots) {
  # Points: highest ranked gets length(ballot) points, then decreasing by 1
  ranks <- seq_along(ballot)
  points <- length(ballot) - ranks + 1
  for (i in seq_along(ballot)) {
    species <- ballot[i]
    scores[[species]] <- (scores[[species]] %||% 0) + points[i]
  }
}

# Convert to a data frame for easier viewing
scores_df <- data.frame(
  species = names(scores),
  score = unlist(scores),
  stringsAsFactors = FALSE
)

# Get the species with the highest Borda score
winner_borda <- scores_df$species[which.max(scores_df$score)]
print(scores_df)
print(paste("Borda count winner:", winner_borda))

