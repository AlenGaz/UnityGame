using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "AI Data", menuName = "Custom/AI Data", order = 1)]
public class AIData : ScriptableObject
{
    [System.Serializable]
    public class AISpell
    {
        public Spell spell;
        public float spellChance;
    }

    [Header("Core Stats")]
    public int aiID;
    public string Name;
    public float MaxHealth;
    public float MaxMana;
    public float HealthRegen;
    public float ManaRegen;
    public float Damage;
    public int Level;
    public float Speed;
    [Tooltip("time in seconds for each attack")] public float AttackSpeed;
    public float AttackRange;
    public List<AISpell> spells = new List<AISpell>();
    [Header("Aggro & Attack")]
    public bool AutoAggro;
    public float aggroRange;
    public float maxChaseDistance;
    public float attackSpeed;
    [Header("Rewards")]
    public float EXP;
    public List<InventoryItem> items = new List<InventoryItem>();
    [Header("Prefabs")]
    public GameObject prefab;

    public bool canCastSpell { get { return spells.Count > 0; } }
}
