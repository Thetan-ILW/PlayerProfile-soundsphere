# how2install

1. Download the code using green (or blue) button  that says `Code` on the top of this page.
2. Open your soundsphere directory on your drive.
3. Create `moddedgame` directory if it does not exist
4. Unpack this mod there. Here is how the path should look: `soundsphere/moddedgame/PlayerProfile-soundsphere/mod.lua`

# what is this
This thing adds something like a local profile to soundsphere. Specifically: 
1. osu performance points and average accuracy
2. osu levels
3. osu rank (pretty damn accurate)
4. Dan clears (4k, 7k, 10k)
5. MSD
6. Live MSD (scores lose their value over time)

# score requirements
For all charts:
1. Minimum 85.00% osu!mania V1 OD9 accuracy
2. 0 pauses
3. The PP of the new score should be higher than the PP of the previous score

For dans:
1. Look at the scoring system and accuracy fields here https://github.com/Thetan-ILW/PlayerProfile-soundsphere/blob/main/player_profile/dans.lua
2. 0 pauses
3. Music speed should be >= 1

I use formulas from osu! wiki, everything should be 1:1 compared to osu  
PP, accuracy and score are calculated using osu!mania V1 OD9
