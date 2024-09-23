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