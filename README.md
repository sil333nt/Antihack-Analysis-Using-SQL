Anti-Hack Analysis Using SQL

Project Overview

This project investigates how gameplay data can be used to identify potential cheating behaviour in online games.

Using a publicly available anti-cheat dataset, I independently conducted a SQL-based investigation into four types of hacks: Aimbot, God Mode, Infinite Ammo, and Speed Hack.

The analysis was structured around four hypotheses, each examining whether specific gameplay metrics exhibited abnormal patterns among players flagged for different hacks. A bonus analysis was also conducted to investigate the co-occurrence of multiple hacks and identify the most prevalent cheating behaviours.

All data preparation, analysis, statistical calculations, and findings were performed entirely in MySQL.

Dataset

Source: Mendeley Data – Anti-Cheat Dataset

Link: https://data.mendeley.com/datasets/bx3y8ktrsf/1

Data: Player gameplay activity, performance metrics, and hack indicators.

Hacks investigated: Aimbot, God Mode, Infinite Ammo, and Speed Hack.

Analysis & Key Findings

1. Aimbot Detection

Hypothesis: Aimbot users would exhibit lower aiming angle errors and higher shooting accuracy than legitimate players.

SQL Analysis:

Compared average aiming angle errors and accuracy rates across legitimate players, aimbot users, and other cheaters.

Calculated correlations between aiming angle error and shooting accuracy for each player group.

Investigated whether aimbot users relied on software-assisted targeting rather than naturally aligning their crosshairs.

Key Findings:

Aimbot users exhibited higher average aiming angle errors despite achieving higher shooting accuracy.

Legitimate players and other cheaters demonstrated a stronger relationship between crosshair alignment and shooting accuracy.

This suggests that aimbot users may achieve high accuracy despite poorer natural aiming alignment.

2. God Mode Detection

Hypothesis: God Mode users would maintain abnormally high health despite receiving damage and participating in combat.

SQL Analysis:

Compared average health, minimum health, damage received, and combat activity across player groups.

Identified potential health conservation violations, defined as receiving damage while maintaining at least 95% average health.

Key Findings:

God Mode users maintained higher average health despite receiving substantially more damage.

Approximately one-third of their combat windows exhibited potential health conservation violations.

This provides a potential indicator for identifying players using health-related hacks.

3. Infinite Ammo Detection

Hypothesis: Infinite Ammo users would exhibit abnormal ammunition depletion patterns during active shooting periods.

SQL Analysis:

Compared shooting activity, ammunition levels, ammunition consumption, and infinite ammunition ratios.

Investigated windows where ammunition consumption was zero despite active shooting.

Tested a manually tuned threshold of infinite_ammo_ratio >= 0.5.

Key Findings:

Infinite Ammo users exhibited higher shooting activity and abnormal ammunition depletion patterns.

The selected threshold achieved:

100% precision

69.22% detection rate (recall)

This demonstrated the potential of ammunition-related metrics as indicators for detecting Infinite Ammo usage within the analysed dataset.

4. Speed Hack Detection

Hypothesis: Speed Hack users would exhibit significantly higher movement speeds than legitimate players.

SQL Analysis:

Compared average and maximum movement speeds across player groups.

Examined the variability of peak speeds.

Investigated damage received as an additional indicator of combat exposure.

Key Findings:

Speed Hack users exhibited more than twice the average mean speed of legitimate players.

They also received substantially more damage on average, potentially suggesting more aggressive gameplay.

An unexpected observation was that legitimate players had an absolute peak speed of 1, which could indicate data labelling issues or undocumented game mechanics requiring further investigation.

5. Bonus Analysis: Hack Co-occurrence

Objective: Investigate whether players tend to use multiple hacks simultaneously and identify the most prevalent hack types.

SQL Analysis:

Grouped flagged cheating windows by combinations of the four hack indicators.

Ranked hack combinations by frequency.

Examined the prevalence of individual hack types.

Key Findings:

The most common combination involved all four hack categories being active simultaneously.

Aimbot was the most prevalent hack, followed by God Mode.

Key SQL Techniques

The project involved the following SQL techniques:

Data Cleaning & Transformation: CAST(), STR_TO_DATE(), REPLACE(), SUBSTRING_INDEX()

Aggregations: GROUP BY, COUNT(), SUM(), AVG(), MIN(), MAX()

Conditional Logic: CASE WHEN for player cohort classification and conditional aggregations.

Statistical Analysis: Correlation calculations, standard deviation, and percentage-based comparisons.

Window Functions: OVER() for calculating the proportion of different hack combinations.

Further Analysis & Improvements

While the hypothesis-driven investigation identified several potentially suspicious gameplay patterns, the current approach relies on manually defined heuristics and aggregate comparisons.

Further improvements could include:

Comprehensive Exploratory Data Analysis: Investigate the full dataset to understand feature distributions, outliers, correlations, and relationships between gameplay metrics.

Predictive Classification: Develop classification models to identify potential cheaters and distinguish between different hack categories, rather than relying solely on manually defined thresholds.

Detection Performance Evaluation: Evaluate detection mechanisms using precision, recall, F1-score, and other relevant metrics, with particular attention to minimising false positives that could affect legitimate players.

Further Investigation of Anomalies: Examine unexpected observations and potential data quality issues to distinguish genuine cheating behaviour from normal gameplay mechanics.

Tools & Technologies

MySQL: Used exclusively for data cleaning, transformation, statistical analysis, hypothesis testing, and investigative queries.

Project Files

Antihack.sql – Complete SQL script containing data preparation, four hypothesis investigations, and bonus hack co-occurrence analysis.
