require 'ffxi.enums'
Dice = {
    CorsairRoll_IDs = {
        [98] = 'Fighter\'s Roll',
        [99] = 'Monk\'s Roll',
        [100] = 'Healer\'s Roll',
        [101] = 'Wizard\'s Roll',
        [102] = 'Warlock\'s Roll',
        [103] = 'Rogue\'s Roll',
        [104] = 'Gallant\'s Roll',
        [105] = 'Chaos Roll',
        [106] = 'Beast Roll',
        [107] = 'Choral Roll',
        [108] = 'Hunter\'s Roll',
        [109] = 'Samurai Roll',
        [110] = 'Ninja Roll',
        [111] = 'Drachen Roll',
        [112] = 'Evoker\'s Roll',
        [113] = 'Magus\'s Roll',
        [114] = 'Corsair\'s Roll',
        [115] = 'Puppet Roll',
        [116] = 'Dancer\'s Roll',
        [117] = 'Scholar\'s Roll',
    },

    CorsairRoll_Data = {
        ['Corsair\'s Roll'] = {
            ['Job'] = Jobs.Corsair,
            ['lucky'] = 5,
            ['unlucky'] = 9,
            ['rolls'] = { 10, 11, 11, 12, 20, 13, 15, 16, 8, 17, 24 },
            ['bonus'] = 0,
            ['effect'] = 2,
            ['bust'] = 6,
            ['desc'] = 'Experience Points'
        },
        ['Ninja Roll'] = {
            ['Job'] = Jobs.Ninja,
            ['lucky'] = 4,
            ['unlucky'] = 8,
            ['rolls'] = { 4, 6, 8, 25, 10, 12, 14, 2, 17, 20, 30 },
            ['bonus'] = 15,
            ['effect'] = 2,
            ['bust'] = 10,
            ['desc'] = 'Evasion'
        },
        ['Hunter\'s Roll'] = {
            ['Job'] = Jobs.Ranger,
            ['lucky'] = 4,
            ['unlucky'] = 8,
            ['rolls'] = { 10, 13, 15, 40, 18, 20, 25, 5, 27, 30, 50 },
            ['bonus'] = 15,
            ['effect'] = 5,
            ['bust'] = 15,
            ['desc'] = 'Accuracy'
        },
        ['Chaos Roll'] = {
            ['Job'] = Jobs.DarkKnight,
            ['lucky'] = 4,
            ['unlucky'] = 8,
            ['rolls'] = { 6.25, 7.81, 9.37, 25, 10.93, 12.5, 15.62, 3.12, 17.18, 18.75, 31.25 },
            ['bonus'] = 9.76,
            ['effect'] = 3,
            ['bust'] = 10,
            ['desc'] = 'Attack'
        },
        ['Magus\'s Roll'] = {
            ['Job'] = Jobs.bluemage,
            ['lucky'] = 2,
            ['unlucky'] = 6,
            ['rolls'] = { 5, 20, 6, 8, 9, 3, 10, 13, 14, 15, 25 },
            ['bonus'] = 8,
            ['effect'] = 2,
            ['bust'] = 8,
            ['desc'] = 'Magic Defense Bonus'
        },
        ['Healer\'s Roll'] = {
            ['Job'] = Jobs.WhiteMage,
            ['lucky'] = 3,
            ['unlucky'] = 7,
            ['rolls'] = {2, 3, 10, 4, 4, 5, 1, 6, 7, 7, 12},
            ['bonus'] = 4,
            ['effect'] = 3,
            ['bust'] = 4,
            ['desc'] = 'Resting MP'
        },
        ['Drachen Roll'] = {
            ['Job'] = Jobs.Dragoon,
            ['lucky'] = 4,
            ['unlucky'] = 8,
            ['rolls'] = { 10, 13, 15, 40, 18, 20, 25, 5, 28, 30, 50 },
            ['bonus'] = 15,
            ['effect'] = 5,
            ['bust'] = 15,
            ['desc'] = 'Pet: Accuracy / Ranged Accuracy'
        },
        ['Choral Roll'] = {
            ['Job'] = Jobs.Bard,
            ['lucky'] = 2,
            ['unlucky'] = 6,
            ['rolls'] = { 8, 42, 11, 15, 19, 4, 23, 27, 31, 35, 50 },
            ['bonus'] = 25,
            ['effect'] = 4,
            ['bust'] = 25,
            ['desc'] = 'Spell Interruption Rate down'
        },
        ['Monk\'s Roll'] = {
            ['Job'] = Jobs.Monk,
            ['lucky'] = 3,
            ['unlucky'] = 7,
            ['rolls'] = { 8, 10, 32, 12, 14, 16, 4, 20, 22, 24, 40 },
            ['bonus'] = 10,
            ['effect'] = 5,
            ['bust'] = 10,
            ['desc'] = 'Subtle Blow'
        },
        ['Beast Roll'] = {
            ['Job'] = Jobs.Beastmaster,
            ['lucky'] = 4,
            ['unlucky'] = 8,
            ['rolls'] = { 6.25, 7.81, 9.37, 25, 10.93, 12.50, 15.62, 3.12, 17.18, 18.75, 31.25 },
            ['bonus'] = 9.76,
            ['effect'] = 3,
            ['bust'] = 10,
            ['desc'] = 'Pet: Attack / Ranged Attack'
        },
        ['Samurai Roll'] = {
            ['Job'] = Jobs.Samurai,
            ['lucky'] = 2,
            ['unlucky'] = 6,
            ['rolls'] = { 8, 32, 10, 12, 14, 4, 16, 20, 22, 24, 40 },
            ['bonus'] = 10,
            ['effect'] = 4,
            ['bust'] = 10,
            ['desc'] = 'Store TP'
        },
        ['Evoker\'s Roll'] = {
            ['Job'] = Jobs.Summoner,
            ['lucky'] = 5,
            ['unlucky'] = 9,
            ['rolls'] = { 1, 1, 1, 1, 3, 2, 2, 2, 1, 3, 4 },
            ['bonus'] = 1,
            ['effect'] = 1,
            ['bust'] = 'Unknown',
            ['desc'] = 'Refresh'
        },
        ['Rogue\'s Roll'] = {
            ['Job'] = Jobs.Thief,
            ['lucky'] = 5,
            ['unlucky'] = 9,
            ['rolls'] = { 1, 2, 3, 4, 10, 5, 6, 7, 1, 8, 14 },
            ['bonus'] = 5,
            ['effect'] = 1,
            ['bust'] = 5,
            ['desc'] = 'Critical Hite Rate'
        },
        ['Warlock\'s Roll'] = {
            ['Job'] = Jobs.RedMage,
            ['lucky'] = 4,
            ['unlucky'] = 8,
            ['rolls'] = { 2, 3, 4, 12, 5, 6, 7, 1, 8, 9, 15 },
            ['bonus'] = 5,
            ['effect'] = 1,
            ['bust'] = 5,
            ['desc'] = 'Magic Accuracy'
        },
        ['Fighter\'s Roll'] = {
            ['Job'] = Jobs.Warrior,
            ['lucky'] = 5,
            ['unlucky'] = 9,
            ['rolls'] = { 1, 2, 3, 4, 10, 5, 6, 6, 1, 7, 15 },
            ['bonus'] = 5,
            ['effect'] = 1,
            ['bust'] = 'Unknown',
            ['desc'] = 'Double Attack'
        },
        ['Puppet Roll'] = {
            ['Job'] = Jobs.Puppetmaster,
            ['lucky'] = 3,
            ['unlucky'] = 7,
            ['rolls'] = { 5, 8, 35, 11, 14, 18, 2, 22, 26, 30, 40 },
            ['bonus'] = 12,
            ['effect'] = 3,
            ['bust'] = 12,
            ['desc'] = 'Pet: Magic Accuracy / Magic Attack Bonus'
        },
        ['Gallant\'s Roll'] = {
            ['Job'] = Jobs.Paladin,
            ['lucky'] = 3,
            ['unlucky'] = 7,
            ['rolls'] = { 4.69, 5.86, 19.53, 7.03, 8.59, 10.16, 3.13, 11.72, 13.67, 15.63, 23.44 },
            ['bonus'] = 11.72,
            ['effect'] = 2.34,
            ['bust'] = '-11.72',
            ['desc'] = 'Defense'
        },
        ['Wizard\'s Roll'] = {
            ['Job'] = Jobs.BlackMage,
            ['lucky'] = 5,
            ['unlucky'] = 9,
            ['rolls'] = { 4, 6, 8, 10, 25, 12, 14, 17, 2, 20, 30 },
            ['bonus'] = 10,
            ['effect'] = 2,
            ['bust'] = 10,
            ['desc'] = 'Magic Attack Bonus'
        },
        ['Dancer\'s Roll'] = {
            ['Job'] = Jobs.Dancer,
            ['lucky'] = 3,
            ['unlucky'] = 7,
            ['rolls'] = { 3, 4, 12, 5, 6, 7, 1, 8, 9, 10, 16 },
            ['bonus'] = 4,
            ['effect'] = 2,
            ['bust'] = 4,
            ['desc'] = 'Regen'
        },
        ['Scholar\'s Roll'] = {
            ['Job'] = Jobs.Scholar,
            ['lucky'] = 2,
            ['unlucky'] = 6,
            ['rolls'] = { 2, 10, 3, 4, 4, 1, 5, 6, 7, 7, 12 },
            ['bonus'] = 3,
            ['effect'] = 'Unknown',
            ['bust'] = 3,
            ['desc'] = 'Conserve MP'
        },
    },

    PercentageRolls = {
        'Chaos Roll', 'Corsair\'s Roll', 'Choral Roll', 'Beast Roll', 'Rogue\'s Roll', 'Fighter\'s Roll',
        'Gallant\'s Roll', 'Scholar\'s Roll'
    },

    -- data https://www.ffxionline.com/forum/ffxi-game-related/race-job-type-q-a/corsair/56520-phantom-roll-knowing-the-odds-long-math
    RollOdds = {
        ['Group 1'] = {
            ['dice'] = { 'Magus Roll', 'Choral Roll', 'Samurai Roll' }, -- 2/6 Rolls
            ['safe'] = { 1, 3, 4, 5, 6 },
            ['safe odds'] = 'Lucky 2: 19.44%, 7: 19.36%, 8: 16.58%, 9: 16.58%, 10: 13.34%, 11: 9.56%, Bust: 5.15%',
            ['moderate'] = { 1, 3, 4, 5, 6, 7 },
            ['moderate odds'] = 'Lucky 2: 19.44%, 8: 19.80%, 9: 19.80%, 10: 16.56%, 11: 12.78%, Bust: 11.60%',
            ['risky'] = { 1, 3, 4, 5, 6, 7, 8 },
            ['risky odds'] = 'Lucky 2: 19.44%, 9: 23.10%, 10: 19.86%, 11: 16.08%, Bust: 21.49%',
        },
        ['Group 2'] = {
            ['dice'] = { 'Healer\'s Roll', 'Monk\'s Roll', 'Drachen Roll', 'Gallant\'s Roll' }, -- 3/7 Rolls
            ['safe'] = { 1, 2, 4, 5, 7 },
            ['safe odds'] = 'Lucky 3: 22.69%, 6: 30.88%, 8: 13.80%, 9: 10.56%, 10: 10.56%, 11: 6.78%, Bust: 4.74%',
            ['moderate'] = { 1, 2, 4, 5, 6, 7 },
            ['moderate odds'] = 'Lucky 3: 22.69%, 8: 19.80%, 9: 16.56%, 10: 16.56%, 11: 12.78%, Bust: 11.60%',
            ['risky'] = { 1, 2, 4, 5, 6, 7, 8 },
            ['risky odds'] = 'Lucky 3: 22.69%, 9: 19.86%, 10: 19.86%, 11: 16.08%, Bust: 21.49%',
        },
        ['Group 3'] = {
            ['dice'] = { 'Ninja Roll', 'Hunter\'s Roll', 'Chaos Roll', 'Puppet Roll', 'Beast Roll', 'Warlock\'s Roll' }, -- 4/8 Rolls
            ['safe'] = { 1, 2, 3, 5, 8 },
            ['safe odds'] = 'Lucky 4: 26.47%, 6: 30.88%, 7: 14.21%, 9: 10.10%, 10: 6.32%, 11: 6.32%, Bust: 5.72%',
            ['moderate'] = { 1, 2, 3, 5, 6, 8 },
            ['moderate odds'] = 'Lucky 4: 26.47%, 7: 19.36%, 9: 16.10%, 10: 12.32%, 11: 12.32%, Bust: 13.43%',
            ['risky'] = { 1, 2, 3, 5, 6, 7, 8 },
            ['risky odds'] = 'Lucky 4: 26.47%, 9: 19.86%, 10: 16.08%, 11: 16.08%, Bust: 21.49%',
        },
        ['Group 4'] = {
            ['dice'] = { 'Corsair\'s Roll', 'Evoker\'s Roll', 'Rogue\'s Roll', 'Fighter\'s Roll', 'Wizard\'s Roll' }, -- 5/9 Rolls
            ['safe'] = { 1, 2, 3, 4, 9 },
            ['safe odds'] = 'Lucky 5: 30.88%, 6: 30.88%, 7: 14.21%, 8: 11.43%, 10: 5.78%, 11: 1.37%, Bust: 5.46%',
            ['moderate'] = { 1, 2, 3, 4, 6, 9 },
            ['moderate odds'] = 'Lucky 5: 30.88%, 7: 19.36%, 8: 16.58%, 10: 11.78%, 11: 7.37%, Bust: 14.04%',
            ['risky'] = { 1, 2, 3, 4, 6, 7, 9 },
            ['risky odds'] = 'Lucky 5: 30.88%, 8: 19.80%, 10: 15.54%, 11: 11.13%, Bust: 22.63%',
        },
    },
}

return Dice;
