# lvlup_rental

rental script that uses oxmysql to store the rented vehicle info, ox_lib for notifications, lvlup_core for ped spawn/de-spawning, and ox_lib for inventory item handling (and metadata)

YOU MUST CREATE THE FOLLOWING ITEM IN OX_INVENTORY

```lua
    ['rental_papers'] = {
        label = 'Rental Agreement',
        weight = 10,
        stack = false
    },
```
