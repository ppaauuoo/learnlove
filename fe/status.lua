Weapon = {
	sword = {
		range = 1,
		multiply = 'str'
	},
	axe = {
		range = 1,
		multiply = 'str'
	},
	lance = {
		range = 1,
		multiply = 'str'
	},
	bow = {
		range = 2,
		multiply = 'str'
	},
	tome = {
		range = 2,
		multiply = 'int'
	}
}

Class = {
	knight = {
		move = 5,
		type = 'ground', -- fly, ground, mount, 
		weak = {Weapon.lance}, -- axe, sword, bow, mag
		equipable = {Weapon.sword}
	},
	cavalier = {
		move = 7,
		type = 'mount', -- fly, ground, mount, 
		weak = {Weapon.axe}, -- axe, sword, bow, mag
		equipable = {Weapon.lance}
	},
	babarian = {
		move = 5,
		type = 'ground', -- fly, ground, mount, 
		weak = {Weapon.sword}, -- axe, sword, bow, mag
		equipable = {Weapon.axe}
	},
	archer = {
		move = 5,
		type = 'ground', -- fly, ground, mount, 
		weak = {}, -- axe, sword, bow, mag
		equipable = {Weapon.bow}
	},
	mage = {
		move = 5,
		type = 'ground', -- fly, ground, mount, 
		weak = {Weapon.bow}, -- axe, sword, bow, mag
		equipable = {Weapon.tome}
	},
}

Character = {
	 {
	 	name = 'a',
		str = 5, -- phy dmg
		mag = 5, -- mag dmg
		agi = 5, -- attack first
		lck = 5, -- crit chance 
		vit = 5, -- hp
		def = 5, -- phy def
		res = 5, -- mag def
		class = Class.knight,
	}
}

