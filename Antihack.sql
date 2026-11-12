DROP DATABASE IF EXISTS antihack;
CREATE DATABASE antihack;
USE antihack;

SELECT * FROM player_data;

CREATE TABLE player_data_clean AS
SELECT
	-- Convert timestamp by stripping +00:00 and cast to DATETIME
    STR_TO_DATE(LEFT(timestamp, 19), "%Y-%m-%d %H:%i:%s") AS match_timestamp,
    
    -- Convert cheat target labels to INT 0/1
    CAST(SUBSTRING_INDEX(es_trampa_max, ",", 1) AS UNSIGNED) AS is_cheater,
    CAST(SUBSTRING_INDEX(isAimbot_max, ",", 1) AS UNSIGNED) AS is_aimbot,
    CAST(SUBSTRING_INDEX(isVidaInfinita_max, ",", 1) AS UNSIGNED) AS is_god_mode,
    CAST(SUBSTRING_INDEX(isMunicionInfinita_max, ",", 1) AS UNSIGNED) AS is_infinite_ammo,
    CAST(SUBSTRING_INDEX(isSuperVelocidad_max, ",", 1) AS UNSIGNED) AS is_speed_hack,
    
    -- Convert feature variables to floats (DOUBLE in SQL syntax)
    CAST(REPLACE(angle_error_mean, ",", ".") AS DOUBLE) AS angle_error_mean,
    CAST(REPLACE(angle_error_max, ",", ".") AS DOUBLE) AS angle_error_max,
    CAST(REPLACE(speed_mean, ",", ".") AS DOUBLE) AS speed_mean,
    CAST(REPLACE(speed_max, ",", ".") AS DOUBLE) AS speed_max,
    CAST(REPLACE(is_shot_sum, ",", ".") AS DOUBLE) AS is_shot_sum,
    CAST(REPLACE(is_hit_sum, ",", ".") AS DOUBLE) AS is_hit_sum,
    CAST(REPLACE(is_received_damage_sum, ",", ".") AS DOUBLE) AS is_received_damage_sum,
    CAST(REPLACE(health_mean, ",", ".") AS DOUBLE) AS health_mean,
    CAST(REPLACE(ammo_left_min, ",", ".") AS DOUBLE) AS ammo_left_min,
    CAST(REPLACE(ammo_max, ",", ".") AS DOUBLE) AS ammo_max,
    CAST(REPLACE(accuracy_rate, ",", ".") AS DOUBLE) AS accuracy_rate,
    CAST(REPLACE(infinite_ammo_ratio, ",", ".") AS DOUBLE) AS infinite_ammo_ratio
FROM player_data;
    
SELECT 
    match_timestamp,
    angle_error_mean,
    speed_max,
    accuracy_rate,
    is_cheater,
    is_aimbot,
    is_speed_hack
FROM player_data_clean
LIMIT 10;

-- Hypothesis 1: Aimbot users will have much lower angle_error_mean, angle_error_max and higher accuracy_rate than normal players
SELECT 
	is_cheater, 
    is_aimbot,
    ROUND(AVG(angle_error_mean), 4) AS avg_angle_error,
    ROUND(AVG(angle_error_max), 4) AS avg_max_angle_error,
    ROUND(AVG(accuracy_rate), 4) AS avg_accuracy_rate
FROM player_data_clean
WHERE is_shot_sum > 0
GROUP BY is_cheater, is_aimbot;

### Surprised by output, where cheaters have higher avg_angle_error but yet higher avg_accuracy
### Secondary hypothesis, aimbot users have crosshair poorly placed and rely heavily on aimbot to help snap crosshair

SELECT 
    is_cheater,
    is_aimbot,
    COUNT(*) AS total_windows,
    ROUND(AVG(angle_error_mean), 4) AS avg_angle_error,
    ROUND(AVG(accuracy_rate), 4) AS avg_accuracy,
    ROUND(AVG(accuracy_rate * angle_error_mean), 4) AS snap_accuracy_index
FROM player_data_clean
WHERE is_shot_sum > 0
GROUP BY is_cheater, is_aimbot;

### We need to verify that lower angle_error is correlated with higher accuracy

SELECT 
    CASE 
        WHEN is_cheater = 0 THEN 'Legitimate Player'
        WHEN is_aimbot = 1 THEN 'Confirmed Aimbot'
        ELSE 'Other Cheater'
    END AS player_cohort,
    COUNT(*) AS n,
    ROUND(
        (COUNT(*) * SUM(angle_error_mean * accuracy_rate) - SUM(angle_error_mean) * SUM(accuracy_rate)) /
        (SQRT(COUNT(*) * SUM(POW(angle_error_mean, 2)) - POW(SUM(angle_error_mean), 2)) *
         SQRT(COUNT(*) * SUM(POW(accuracy_rate, 2)) - POW(SUM(accuracy_rate), 2))),
        4
    ) AS correlation_angle_vs_accuracy
FROM player_data_clean
WHERE is_shot_sum > 0
GROUP BY player_cohort;

### Confirmed, legitimate players and other cheaters align their crosshair for accuracy, while Aimbot cheaters rely on software snaps

-- Hypothesis 2: Players with active God Mode (is_god_mode = 1) sustain abnormal damage absorption (is_received_damage_sum) while maintaining a locked, near-maximum health state (health_mean), accompanied by a higher combat exposure (is_hit_sum) compared to legitimate players.

SELECT 
    CASE 
        WHEN is_god_mode = 1 THEN 'God Mode Active'
        WHEN is_cheater = 0 THEN 'Legitimate Player'
        ELSE 'Other Cheat'
    END AS cohort,
    COUNT(*) AS total_windows,
    ROUND(AVG(health_mean), 4) AS avg_health,
    ROUND(MIN(health_mean), 4) AS min_health,
    ROUND(AVG(is_received_damage_sum), 4) AS avg_damage_received,
    ROUND(MAX(is_received_damage_sum), 4) AS max_damage_received,
    ROUND(AVG(is_hit_sum), 4) AS avg_hits_landed
FROM player_data_clean
GROUP BY cohort;

#Confirmed, God mode cheaters have higher average health, take much more damage on average, and is involved in more combats

SELECT 
    CASE 
        WHEN is_god_mode = 1 THEN 'God Mode Active'
        WHEN is_cheater = 0 THEN 'Legitimate Player'
        ELSE 'Other Cheat'
    END AS cohort,
    COUNT(*) AS total_windows,
    SUM(CASE WHEN is_received_damage_sum > 0 AND health_mean >= 0.95 THEN 1 ELSE 0 END) AS high_dmg_full_health_windows,
    ROUND(
        100.0 * SUM(CASE WHEN is_received_damage_sum > 0 AND health_mean >= 0.95 THEN 1 ELSE 0 END) / COUNT(*), 
        2
    ) AS pct_conservation_violations
FROM player_data_clean
GROUP BY cohort;
    
### God Mode players average 1 in 3 combat windows where they were supposed to take damage and yet stayed near full health.

-- Hypothesis 3: Players running infinite ammo hacks (`is_infinite_ammo = 1`) violate resource depletion mechanics. During firing windows, their minimum ammunition count (`ammo_left_min`) will fail to decrease normally, resulting in an unnaturally elevated `infinite_ammo_ratio` and higher baseline `ammo_max` retention compared to legitimate players.

SELECT
	CASE
		WHEN is_infinite_ammo = 1 THEN 'Infinite Ammo Active'
        WHEN is_cheater = 0 THEN 'Legitimate Player'
        ELSE 'Other Cheat'
	END AS cohort,
    COUNT(*) AS total_windows,
    ROUND(AVG(is_shot_sum), 4) AS avg_shot_activity,
    ROUND(AVG(ammo_max), 4) AS avg_ammo_max,
    ROUND(AVG(ammo_left_min), 4) AS avg_ammo_left_min,
    ROUND(AVG(ammo_max - ammo_left_min), 4) AS avg_ammo_consumed,
    ROUND(AVG(infinite_ammo_ratio), 4) AS avg_infinite_ammo_ratio,
    ROUND(MAX(infinite_ammo_ratio), 4) AS peak_infinite_ammo_ratio
FROM player_data_clean
WHERE is_shot_sum > 0
GROUP BY cohort;

### Infinite ammo hackers shoot more than the other groups, and their ammo is never deleted

SELECT
	CASE
		WHEN is_infinite_ammo = 1 THEN 'Infinite Ammo Active'
        WHEN is_cheater = 0 THEN 'Legittimate Player'
        ELSE 'Other Cheat'
	END AS cohort,
    COUNT(*) AS firing_windows,
    SUM(CASE WHEN (ammo_max - ammo_left_min) = 0 THEN 1 ELSE 0 END) AS zero_depletion_windows,
    ROUND(
		100 * SUM(CASE WHEN (ammo_max - ammo_left_min) = 0 THEN 1 ELSE 0 END)/COUNT(*), 2
	) AS pct_zero_depletion,
    SUM(CASE WHEN infinite_ammo_ratio>= 0.5 then 1 ELSE 0 END) AS ratio_flagged_windows,
    ROUND(
		100 * SUM(CASE WHEN infinite_ammo_ratio>= 0.5 then 1 ELSE 0 END)/COUNT(*), 2
	) AS pct_ratio_flagged
FROM player_data_clean
WHERE is_shot_sum > 0
GROUP BY cohort;
    
### Using the filter infinite_ammo_ratio >= 0.5 (tunable), we were able to achieve 100% precision
### and 0% false positives, with a 69.22% catch rate for Infinite Ammo Active hackers. 

-- Hypothesis 4: Speed hackers will have higher speed_mean, speed_max, is_received_damage_sum than legitimate players
    
SELECT
	CASE
		WHEN is_speed_hack = 1 THEN 'Speed Hack Active'
        WHEN is_cheater = 0 THEN 'Legitimate Player'
        ELSE 'Other Cheat'
	END AS cohort,
    COUNT(*) AS total_windows,
    ROUND(AVG(speed_mean), 4) AS avg_speed_mean,
    ROUND(AVG(speed_max), 4) AS avg_speed_max,
    ROUND(MAX(speed_max), 4) AS absolute_peak_speed,
    ROUND(STDDEV(speed_max), 4) AS std_peak_speed,
    ROUND(AVG(is_received_damage_sum), 4) AS avg_damage_received,
    ROUND(MAX(is_received_damage_sum), 4) AS max_damage_received
FROM player_data_clean
GROUP BY cohort;
    
### Speed hackers have more than 2x the average mean speed of legitimate players, 
### as a result they might play more recklessly, taking much more damage than legitimate players.
### Legitimate Player absolute_peak_speed is 1, which possibly points to error labeling or hidden game-mechanics.

-- Bonus Analysis: Hacks Co-occurence

SELECT
	is_aimbot,
    is_speed_hack,
    is_god_mode,
    is_infinite_ammo,
    COUNT(*) AS window_count,
    ROUND(100 * COUNT(*)/SUM(COUNT(*)) OVER(), 2) AS pct_of_cheat_windows
FROM player_data_clean
WHERE is_cheater = 1
GROUP BY is_aimbot, is_speed_hack, is_god_mode, is_infinite_ammo
ORDER BY window_count DESC;

#Most hackers have all 4 implemented, and aimbot is the most implemented hack, with god mode being the second most.
