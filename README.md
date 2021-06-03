# KłełeAtoms
A game where you have to take atoms from other players by blowing up yours.

## Install instructions
- Download LOVE for your platform from https://love2d.org/.
- Download latest KłełeAtoms release from this repository (https://github.com/Nightwolf-47/KleleAtoms/releases)
- Drag and drop KłełeAtoms .love file to LOVE executable

## How to play
The game starts with an empty grid. Every player can place 1 atom per turn on tiles without enemy atoms.  
When a tile has too many* atoms, it becomes critical and explodes. Each surrounding tile gains an atom and all existing atoms on those tiles go to the player who started the explosion.  
If an explosion causes other atoms to become critical, they will explode as well, causing a chain reaction.  
If a player loses all their atoms, they lose. The last standing player wins the game.  
  
\*corner - 2 atoms, side - 3 atoms, otherwise 4 atoms (or more)

## Credits  
**LOVE Development Team** - Löve, a Lua game engine this game runs on.  
**DrPetter** - SFXR, a tool used to make sounds for this game.  

## License
This game is licensed under the MIT License, see [LICENSE](https://github.com/Nightwolf-47/KleleAtoms/blob/main/LICENSE) for details.
