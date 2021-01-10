# Calvin-Admin-Suite
Extensible set of admin commands used for server moderation, user experience, and general usage in the Roblox environment

Calvin Admin Suite allows the regular user to fully moderate their server through commands like serverlock, kick, and ban or give other users a fun time with fun and party-type 
commands. Wth Calvin Admin Suite, the seemless intregration of Trello allows for utilization of Trello lists and cards to have admins, bans, blacklists, and whitelists. CAS also
allows for specifc administration as well, utilizing groups and group ranks for different admin types, bans, and other administrative features. 

## Setup
  - The way I would set this up is just by downloading the MainModule.rbxm file and extracting it in your Roblox Studio
  - From there the main module, command framework, and the respective dependencies to make the entire module to work will already be present and no further setup will be required
  Extracting the file will give you access to the necessary events and remotes, UIs, and modules to further make CAS work seamlessly. 
  - You can change your settings by going to the config module inside the 'Scripts' folder which is located inside the command framework module
  - From there you can change which admin type have access to which commands, which users or groups are banned, and which users, groups, or specific group members have access to
  different admin types
  
I was going to make it so CAS would connect itself to Modulus and vice versa, but I never got around to doing it. That would unlock a wide variety of features and opportunities 
that would enhance the user experience on both the bot and on the admin itself in-game.
