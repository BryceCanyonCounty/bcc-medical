# bcc-medical

## Description
An all in one player and NPC medic script, formerly known as *Legacy_Medic*, 
combining AIMedic and Medical Script for VORP.

This script allows the choosing of NPC model, command, price, and multijob restriction for the
spawning of an AI Medic to pick you up. This has been improved upon from the original legacy_aimedic and legacy_medic. 
It now includes an injury checking system. Players can check their pulse and last injury as well as those of other players when in range.

Also included, an injury and bleeding system set in the Config file. Stitches item will stop bleeding forever while bandage items stop the bleeding temporarily and saves to the database.
You will bleed from knife and gunshot injuries.

Planned to come: Checking cause of death plus some pretty UI stuff and more! ;)

## Features
- Injury system with bleeding from knife and gunshot injuries as well as stiching and bandages
- Checking cause of wound
- Bleeding
- NPC Model Config
- Price Config using cash or gold
- Command Config
- Job Config
- Translation Files
- Bandages and Revive items Config
- Webhook for revivals
- Doctors offices for collecting equipment
- Alert with gps coordinates sending when doctor is online
- Shaman item that allows players to skip the job check
- Additional possibility to have the NPC-Doc take a percentage amount of money
- Additional possibility for the NPC-Doc to steal items and/or weapons from the player inventory after being revived

## Bleeding
- Database bleed values
  - 0 = Not bleeding
  - 1 = Bleeding
  - 2 = Bleeding temporarily stopped

- Bandage items
  - Can be used by any player for themselves or someone else
  - Will stop bleeding for the length of time set in the config
  - After that time expires bleeding will start again

- Stitches Items
  - Can only be used by a player with a doctor job
  - Will stop bleeding permanently

## Commands
- `/medic` Use in chat to open Medic Menu
- `/sendhelp` Use to Call for NPC Doctor

## Dependencies
- [vorp_core](https://github.com/VORPCORE/vorp-core-lua)
- [vorp_inventory](https://github.com/VORPCORE/vorp_inventory-lua)
- [feather-menu](https://github.com/FeatherFramework/feather-menu/releases)
- [bcc-utils](https://github.com/BryceCanyonCounty/bcc-utils)

## Installation
- Make sure dependencies are installed/updated and ensured before this script
- Add `bcc-medical` folder to your resources folder
- Add `ensure bcc-medical` to your `resources.cfg`
- Run the included database file
- Restart server

## GitHub
- https://github.com/BryceCanyonCounty/bcc-medical
- Need more help? Join the bcc discord here: https://discord.gg/VrZEEpBgZJ