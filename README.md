# bcc-medical

An all in one player and NPC medic script, formerly Legacy_Medic
Combining of AIMedic and Medical Script for VORP

This script allows the choosing of NPC model, command, price, and multijob restriction for the
spawning of an AI Medic to pick you up, this has been improved upon from the original legacy_aimedic and legacy_medic
This also now includes an injury checking system, as a regular player you can check your last injury, and the closest persons injury
As a doctor you can check all of these and the patient pulse too!

This also includes an injury and bleeding system, by default right now the Config.Stitches item will stop bleeding forever, bandage items stop the bleeding temporarily and saves to the database
You will bleed from knife and gunshot injuries

Planned to come: Checking cause of death plus some pretty UI stuff and more! ;)

Features:

-Injury system with bleeding from knife and gunshot injuries as well as stiching and bandages

-Checking cause of wound

-This includes a bleeding

-NPC Model Config

-Price Config

-Command Config

-Job Config

-Translation File

-Bandage and Revive items Config

-Webhook for revivals

-Doctor offices for collecting equipment

#v0.2 Changelogs

-Added Version to fxmanifest (yet to implement version check)
-Added Config Options : `devMode` | `bleedChance` | `StopBleedOnRevive` | `AnimOnBleed` | `toHospital`
-Added option to spawn on spot or send to hospital on NPC revive (`Config.doctors.toHospital`)
-Fixed NPC not reviving players
-Added Config to disable NPC doctor (`Config.doctors.enabled`)
-Changed `dmgtest` command to devMode only
-Removed traces of `Outsider_needs`
