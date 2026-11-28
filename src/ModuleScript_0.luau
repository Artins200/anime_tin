return {
	Order = {"Fists","Pistol","SMG","Shotgun","Rifle","ArcCarbine"},
	Stats = {
		Fists   = {Display="Кулаки",     Damage=28, Cooldown=0.40,  Range=7.5, Pellets=1, Spread=0,   Auto=true,  Knock=45, Color=Color3.fromRGB(255,255,255)},
		Pistol  = {Display="Пистолет",   Damage=24, Cooldown=0.26,  Range=300, Pellets=1, Spread=0.4, Auto=false, Knock=6,  Color=Color3.fromRGB(255,230,120), Recoil=0.6},
		SMG     = {Display="ПП «Рой»",   Damage=10, Cooldown=0.08,  Range=250, Pellets=1, Spread=2.4, Auto=true,  Knock=4,  Color=Color3.fromRGB(120,220,255), Recoil=0.35},
		Shotgun = {Display="Дробовик",   Damage=12, Cooldown=0.85,  Range=90,  Pellets=9, Spread=6,   Auto=false, Knock=12, Color=Color3.fromRGB(255,150,80),  Recoil=2.4},
		Rifle   = {Display="Рельса",     Damage=40, Cooldown=0.90,  Range=600, Pellets=1, Spread=0,   Auto=false, Knock=25, Color=Color3.fromRGB(255,80,200),  Recoil=3.0,
			Charge=true, MaxCharge=1.4, MinDamage=45, MaxDamage=280},
		ArcCarbine = {Display="Дуговой карабин", Damage=54, Cooldown=0.38, Range=360, Pellets=1, Spread=0.25, Auto=false, Knock=18, Color=Color3.fromRGB(78,225,235), Recoil=0.8},
	},
}