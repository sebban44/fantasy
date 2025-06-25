#This calls the API to fetch the fantasy data
#Bootstrap call is for general data
#Loop through to get individual player data per match

library(tidyverse)
library(rvest)
library(jsonlite)

data <- fromJSON("https://fantasy.premierleague.com/api/bootstrap-static/")

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
  player_url <- paste0("https://fantasy.premierleague.com/api/element-summary/", p, "/")
  player_data <- fromJSON(player_url)

  player_history <- player_data$history

  player_df <- bind_rows(player_df, player_history)
}

player_df <- inner_join(player_df,player_list,by=c("element" = "id")) 

#add team and pos to players
player_df <- inner_join(player_df, teams,by = c("team" = "team_id"))
player_df <- inner_join(player_df, teams,by = c("opponent_team" = "team_id"))

write.csv(player_df, "/home/cirseb/Documents/script/football/premier-league/data/fpl_2024_2025.csv")
