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
36-40	multi 3d6+1 caltrops
# this also works with subtables
41-45	multi 1d4+1 { 1-3 wineskin; 4-8 iron rations; 9-10 salted pork; }
# or if you want them to select multiple of all the same item,
# eg. randomly choose wineskin OR iron rations OR salted pork, then return
# 1d4+1 of whichever one was chosen
41-45	group 1d4+1 { 1-3 wineskin; 4-8 iron rations; 9-10 salted pork; }
```
