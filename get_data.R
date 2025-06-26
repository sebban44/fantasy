#This calls the API to fetch the fantasy data
#Set if it should be Allsvenskan or Premier League as input
#Bootstrap call is for general data
#Loop through to get individual player data per match

library(tidyverse)
library(rvest)
library(jsonlite)

api_input <- "Allsvenskan"

if(api_input == "Allsvenskan") {
	url <- "https://fantasy.allsvenskan.se/api/bootstrap-static/"
	p_url <- "https://fantasy.allsvenskan.se/api/element-summary/"
} else {
	url <- "https://fantasy.premierleague.com/api/bootstrap-static/"
	p_url <- "https://fantasy.premierleague.com/api/element-summary/"
}

print(paste0("Starting data collection for: ", api_input, "..."))

data <- fromJSON(url)

teams <- data$teams
teams <- teams %>% select(team_id=id,team_name=name)
players <- data$elements
position <- data$element_type
position <- position %>% select(id,pos=singular_name_short)

players <- inner_join(players,position,by=c("element_type"="id"))

player_list <- players %>% select(id, team, name = web_name, pos ,selected_by_percent)

player_df <- data.frame()

#Go through all players to fetch match history
for (p in player_list$id) {
  player_url <- paste0(p_url, p, "/")
  player_data <- fromJSON(player_url)

  player_history <- player_data$history

  player_df <- bind_rows(player_df, player_history)
}

player_df <- inner_join(player_df,player_list,by=c("element" = "id")) 

#add team and pos to players
player_df <- inner_join(player_df, teams,by = c("team" = "team_id"))
player_df <- inner_join(player_df, teams,by = c("opponent_team" = "team_id"))

#Store in league data the result
if(api_input == "Allsvenskan") {
	write.csv(player_df,"/allsvenskan/data/fantasy_player_data.csv")
} else {
	write.csv(player_df,"premier-league/data/fantasy_player_data.csv")
}

print(paste0("Data retrieved for: ", api_input, "."))
print("Data stored in league folder...")
