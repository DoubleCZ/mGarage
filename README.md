# 🚗 mGarage 2.0.0 - Custom Fork - fakeplate

## 🌍 English Version

This fork modifies the fake plate method by setting it to an empty plate. Additionally, it allows transferring the plate to another vehicle while keeping the trunk and other properties of the original vehicle. This fork is optimized for CZ/SK servers.

---

## 🔧 How to Use?

1️⃣ Add the following items to `ox_inventory/data/items.lua`:

```lua
["hotwire"] = {
    label = "Hotwire",
    description = "Hotwire car",
    weight = 175,
    stack = true,
    server = {
        export = "mVehicle.hotwire"
    }
},

["fakeplate"] = {
    label = "Screwdriver",
    description = "Special Screwdriver to get plate. 10 uses",
    consume = 0,
    stack = false,
    server = {
        export = "mVehicle.fakeplate"
    }
},

["spz"] = {
    label = "Plate",
    consume = 0,
    stack = 0,
    server = {
        export = "mVehicle.plate"
    }
},

["mradio"] = {
    label = "Modular Radio",
    description = "Radio to your car!",
    consume = 0,
    stack = 0,
    server = {
        export = "mVehicle.mradio"
    }
},
```

2️⃣ Use the SQL from the documentation.

---

## 📖 Documentation

📌 [Official Documentation](https://mono-94.github.io/mDocuments/docs/mGarage)


---

## 🇨🇿 Česká verze

Tento fork upravuje metodu falešných SPZ tak, že nastaví prázdnou SPZ. Navíc umožňuje přenesení SPZ na jiné vozidlo při zachování kufru a dalších vlastností původního vozidla. Fork je optimalizován pro CZ/SK servery.

---

## 🔧 Jak to použít?

1️⃣ Přidejte do `ox_inventory/data/items.lua` následující položky:

```lua
["hotwire"] = {
    label = "Hotwire",
    description = "Hotwire car",
    weight = 175,
    stack = true,
    server = {
        export = "mVehicle.hotwire"
    }
},

["fakeplate"] = {
    label = "Screwdriver",
    description = "Special Screwdriver to get plate. 10 uses",
    consume = 0,
    stack = false,
    server = {
        export = "mVehicle.fakeplate"
    }
},

["spz"] = {
    label = "Plate",
    consume = 0,
    stack = 0,
    server = {
        export = "mVehicle.plate"
    }
},

["mradio"] = {
    label = "Modular Radio",
    description = "Radio to your car!",
    consume = 0,
    stack = 0,
    server = {
        export = "mVehicle.mradio"
    }
},
```

2️⃣ Použijte SQL z dokumentace.

---

## 📖 Dokumentace

📌 [Oficiální dokumentace](https://mono-94.github.io/mDocuments/docs/mGarage)

---




