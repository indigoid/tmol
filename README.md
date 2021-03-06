tmol (Twisty Maze Of Lists)
===========================

So I was reading through the D&D 3.5 Dungeon Master's Guide and implemented
a little language for describing the dice-based tables therein.

There's some samples in the data/ directory.

# Language features

At the most basic level, tables from the DMG can be directly transcribed.
Lines starting with # are comments. Leading and trailing whitespace is
ignored.

```
# boring
1-10	sword
11-20	spear
21-25	morningstar
# Flails are badass. See: Lord of the Rings
26-30	flail
```

## Inline subtables - for things like the 'mundane items' table in the DMG

```
26-30	{ 1-10 flail; 11-18 dire flail; 19-20 double flail; }
# for equal chance of all items in a subtable, add the even: tag
31-35	{ even: dagger; knife; kris; machete; }
```

## External subtables

```
26-30	@flails.table
```

## Combined inline and external subtables

```
26-30	{ even: @flails.table; @morningstars.table; @chains.table; }
```

## Multiple items

```
# return 4-19 caltrops
36-40	multi 3d6+1 caltrops

# this also works with subtables, but it will roll from the subtable
# every time - 1d4+1 times in this case, so multiple different items
# may be selected (eg. wineskins AND iron rations AND salted pork)
41-45	multi 1d4+1 { 1-3 wineskin; 4-8 iron rations; 9-10 salted pork; }

# or if you want them to select multiple of all the same item,
# eg. randomly choose wineskin OR iron rations OR salted pork, then return
# 1d4+1 of whichever one was chosen
41-45	group 1d4+1 { 1-3 wineskin; 4-8 iron rations; 9-10 salted pork; }

# the 'oneofeach' qualifier will 'execute' every item in a subtable
# eg. this might return a wineskin, 2 iron rations and, 10% of the time,
# some cheese
46-47	oneofeach 1d6 { even: wineskin; multi 1d4 iron rations; 10% cheese; }
```

## Chance

```
# you can put a percentage before any table entry to make it that likely,
# eg. if this table slot comes up on the dice, a percentage roll then
# happens. eg. 2% chance of getting something incredibly valuable
48-50	2% { even: Steve Jobs; Nelson Mandela; Arnold Schwarzenegger; }
```

## Additional properties
```
# The DMG has a few tables where there is a directive to reroll on the
# same table and then add extra properties based on some other table.
# eg. roll a weapon type and then add magical properties (sundering,
# vorpal, etc) to whatever weapon was rolled. This mechanism isn't
# directly replicated but it is pretty close. It could be achieved
# with a construct like the below
1-96	@weapons.table
97-100	append @properties.table @weapons.table
