Overview
--------

This is a deployment and console wrapper for Minecraft which allows for more
convenient administration of a Minecraft server.

Installation
------------

    gem install minecraft

This will install the Minecraft extension library and binary, the Minecraft
server jarfile will be downloaded from http://minecraft.net when the binary is
ran for the first time.

Usage
-----

    mkdir ~/MinecraftServer
    cd ~/MinecraftServer
    minecraft

    minecraft -h

Current Features
----------------

- !give <item> <quantity>
  - Give the user an item with a quantity of up to 2560 (by default Minecraft
  will cap at 64).
  - Use the item ID or item name. http://minecraftwiki.net/wiki/Data_values
- !giveall <item> <quantity>
- !tp <target_user>
- !tpall
- !nom
- !nomall
- !kit <group>
  - Diamond
  - Gold armour
  - Armour
  - Ranged
  - Nether
  - Portal
- !kitall <group>
- !addtimer <item> <frequency>
- !deltimer <item>
- !printtimer
- !list

TODO
----

Contributors
------------

Forks are welcomed, pull requests will be prompty reviewed!

- Ian Horsman

Notice
------

Minecraft is copyright of Mojang AB and developed by Markus Persson (@notch).
