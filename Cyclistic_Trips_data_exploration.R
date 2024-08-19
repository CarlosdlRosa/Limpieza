library("tidyverse")

# Load the dataset into a DataFrame
trips_df <- read_csv("Cyclistic_Trips_2019_Q1.csv")

# Get an overview of the dataset's structure
glimpse(trips_df)

### Part 1: Exploring the Relationship Between Age and User Type

# Group the data by usertype and summarize age-related statistics.
# This produces a tibble, which may not display all the data directly in the console.
trips_df %>%
  group_by(usertype) %>%
  summarize(
    min_birthyear = min(birthyear, na.rm = TRUE),
    Q1_birthyear = quantile(birthyear, probs = 0.25, na.rm = TRUE),
    median_birthyear = median(birthyear, na.rm = TRUE),
    mean_birthyear = mean(birthyear, na.rm = TRUE),
    Q3_birthyear = quantile(birthyear, probs = 0.75, na.rm = TRUE),
    max_birthyear = max(birthyear, na.rm = TRUE),
    sd_birthyear = sd(birthyear, na.rm = TRUE)
  )

# Since the tibble output can be difficult to view in the console,
# we will use the View() command to display it in a more readable format.

View(trips_df %>%
       group_by(usertype) %>%
       summarize(
         min_age = min(2019 - birthyear, na.rm = TRUE),   # Minimum age by user type
         Q1_age = quantile(2019 - birthyear, probs = 0.25, na.rm = TRUE),  # First quartile of age
         median_age = median(2019 - birthyear, na.rm = TRUE),  # Median age
         mean_age = mean(2019 - birthyear, na.rm = TRUE),  # Mean age
         Q3_age = quantile(2019 - birthyear, probs = 0.75, na.rm = TRUE),  # Third quartile of age
         max_age = max(2019 - birthyear, na.rm = TRUE),  # Maximum age
         sd_age = sd(2019 - birthyear, na.rm = TRUE)  # Standard deviation of age
       ))

# Analyze the completeness of the birthyear data by user type
trips_df %>%
  group_by(usertype) %>%
  summarize(
    total_birthyear = n(),  # Total number of birthyear entries by user type
    non_null_birthyear = sum(!is.na(birthyear)),  # Number of non-null birthyear entries
    null_birthyear = sum(is.na(birthyear)),  # Number of null birthyear entries
    non_null_rate = (sum(!is.na(birthyear)) * 100) / n()  # Percentage of non-null birthyear entries
  )

# Filter out records with unrealistic birth years (older than 80 years in 2019)
trips_without_outliers <- filter(trips_df, birthyear > 1939)

# Filter the dataset to remove extreme trip durations and old birth years
trips_filtered <- trips_df %>%
  filter((tripduration / 60) < 100, birthyear > 1939)

# Create a boxplot to visualize the distribution of users' ages by user type
ggplot(data = trips_without_outliers, aes(x = (2019 - birthyear), y = usertype, fill = usertype)) +
  geom_boxplot() +
  labs(title = "User's Age Distribution by User Type",
       x = "Age",
       y = "",
       fill = "Usertype") +
  theme_minimal()

### Part 2: Analyzing the Relationship Between Trip Duration and User Type

# View summary statistics of trip duration by user type
View(trips_df %>%
       group_by(usertype) %>%
       summarize(
         min_tripduration = min(tripduration, na.rm = TRUE),  # Minimum trip duration
         Q1_tripduration = quantile(tripduration, probs = 0.25, na.rm = TRUE),  # First quartile of trip duration
         median_tripduration = median(tripduration, na.rm = TRUE),  # Median trip duration
         mean_tripduration = mean(tripduration, na.rm = TRUE),  # Mean trip duration
         Q3_tripduration = quantile(tripduration, probs = 0.75, na.rm = TRUE),  # Third quartile of trip duration
         max_tripduration = max(tripduration, na.rm = TRUE),  # Maximum trip duration
         sd_tripduration = sd(tripduration, na.rm = TRUE)  # Standard deviation of trip duration
       ))

# Assess the completeness of the trip duration data by user type
trips_df %>%
  group_by(usertype) %>%
  summarize(
    count_tripduration = n(),  # Total number of trip duration entries by user type
    non_null_tripduration = sum(!is.na(tripduration)),  # Number of non-null trip duration entries
    null_tripduration = sum(is.na(tripduration)),  # Number of null trip duration entries
    non_null_rate = (sum(!is.na(tripduration)) * 100) / n()  # Percentage of non-null trip duration entries
  )

# Filter out trips with durations longer than 100 minutes
less_than_100min_trips <- filter(trips_df, (tripduration / 60) < 100)

# Create a boxplot to visualize the distribution of trip durations by user type
ggplot(data = less_than_100min_trips, aes(x = (tripduration / 60), y = usertype, fill = usertype)) +
  geom_boxplot() +
  labs(title = "Trip Duration Distribution by User Type",
       x = "Trip Duration (in minutes)",
       y = "",
       fill = "Usertype") +
  theme_minimal()

### Part 3: Exploring the Relationship Between Age and Trip Duration

# Filter the data to focus on reasonable age and trip duration values
trips_filtered <- trips_df %>%
  filter((tripduration / 60) < 100, birthyear > 1939)

# Create a scatterplot to explore the relationship between age and trip duration without distinguishing user types
ggplot (data = trips_filtered, aes(x = (2019 - birthyear), y = (tripduration /60))) +
  geom_point() +
  labs(title = "Age vs. Trip Duration",
       x = "Age",
       y = "Trip Duration (in minutes)") +
  theme_minimal()

# Create a scatterplot to explore the relationship between age and trip duration, showing the distinction between casual and subscriber users
# Also using geom_jitter to reduce overlap when there are many points on a scatterplot
ggplot(data = trips_filtered, aes(x = (2019 - birthyear), y = (tripduration / 60), color = usertype)) +
  geom_jitter() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(title = "Age vs. Trip Duration by User Type",
       x = "Age",
       y = "Trip Duration (in minutes)",
       color = "Usertype") +
  theme_minimal()
