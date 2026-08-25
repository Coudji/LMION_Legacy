# Engine property aliases and safe writes

Status: **B42.20.3 bytecode verified + runtime/Git-history recovered**

This note explains why LMION does not treat `PropertyContainer:set(name, arbitraryString)` as an ordinary string key/value store.

## The misleading API surface

From Lua, Project Zomboid sprite/object properties look string-based:

```text
properties:set("Material", "Metal")
properties:get("Material")
```

It is tempting to assume the engine stores the exact string that was supplied. In B42.20.3 that assumption is wrong for aliased properties.

## Bytecode evidence

`PropertyContainer.set(String, String, boolean)` resolves the property name through `TilePropertyAliasMap.getIDFromPropertyName(...)`, then resolves the value through:

```text
TilePropertyAliasMap.getIDFromPropertyValue(propertyId, value)
```

B42.20.3 bytecode for `getIDFromPropertyValue` shows:

```text
if possibleValues is empty:
    return 0
else:
    return idMap.getOrDefault(value, 0)
```

The important part is the default: **an unknown value resolves to alias id `0` rather than being preserved as an unknown string**.

`PropertyContainer` then stores the numeric property/value ids. A later `get()` converts that alias id back to a valid engine string.

Therefore this can happen conceptually:

```text
request:  Material = "SomeCustomMaterialName"
engine:   unknown value -> alias id 0
readback: Material = <first/default valid alias>
```

The write did not fail loudly. It silently became a different valid value.

## LMION decision

Engine-facing property writes use a defensive round trip:

```text
1. remember whether the property existed and its previous value
2. write the requested value
3. immediately read it back
4. accept only exact string equality
5. otherwise restore the previous value, or unset it if it did not exist
```

Current Core implementation is the local `setAliasedProperty()` helper in `LMION/Doors.lua`.

This applies to LMION-owned writes such as:

```text
Material
Material2
Material3
MaterialType
DoorSound
ThumpSound
```

The principle is broader than those names: if an engine property is alias-backed, an arbitrary semantic string is unsafe unless it is known to be a valid alias for that property.

## Why this matters for materials

LMION uses door profiles to describe gameplay materials and sounds, but those profile values eventually interact with engine properties used by vanilla systems such as destruction/salvage and sound behavior.

A typo or invented material value must not silently mutate the sprite into another engine material. Exact readback is therefore part of correctness, not merely input validation.

`MaterialType` deserves special care: it is an engine-defined/closed property vocabulary and is not a generic LMION salvage tag.

## Why LMION does not store custom gameplay metadata here

`PropertyContainer` is engine-owned global sprite/object metadata. It is not the right place for arbitrary LMION state.

Persistent LMION-specific state belongs in mechanisms such as:

```text
object:getModData()
inventoryItem:getModData()
LMION profile tables
```

depending on whether the state belongs to a world instance, transported item, or static LMION configuration.

This separation avoids alias coercion and avoids accidentally changing vanilla behavior that reads the same properties.

## Global-sprite implication

LMION applies profile properties to the global `IsoSprite` instances returned by the engine. This means a successful property mutation affects every object that uses that sprite during the running session.

That is intentional for the current profile model, but addon authors must understand that this is not per-object decoration.

## Addon contract

Addon authors should follow these rules when interacting with LMION/engine door properties:

- do not assume `PropertyContainer:set()` preserves arbitrary strings;
- if writing an aliased engine property, verify exact readback;
- on mismatch, restore the previous value instead of leaving the engine's alias-0 fallback in place;
- do not use `Material`, `MaterialType`, `DoorSound`, etc. as a free-form addon data store;
- prefer LMION profile extension or modData for addon-specific semantics;
- remember that modifying a global `IsoSprite` property can affect unrelated instances using the same sprite.

## Revalidation triggers

Recheck this conclusion if Project Zomboid changes `TilePropertyAliasMap`/`PropertyContainer` to preserve unknown strings, expose alias validation directly to Lua, or moves these properties to a different data representation.
