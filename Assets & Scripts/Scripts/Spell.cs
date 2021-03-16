using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "Spell", menuName = "Custom/Spell", order = 1)]
public class Spell : ScriptableObject
{
    public int ID;
    public SpellType type;
    public float Cooldown;
    public AimSpellType aimType;
    public float manaNeeded;
    public float value;
    public float rngRange;
    public bool dealDamage;
    public SpellDirection[] aoe;
    public GridObject prefab;
    public float prefabDestroyTime = 5f;
    public bool castProjectile;
    public GameObject castProjectilePrefab;
}

public enum SpellType
{
    Support,
    Attack,
}
public enum AimSpellType
{
    Instant,
    Aim,
}

public enum SpellDirection
{
    Top, Down, Left, Right, TopLeft, TopRight, DownLeft, DownRight, Middle, Facing, FacingLeft, FacingRight
}