using UnityEngine;

public class SpellDatabase : MonoBehaviour
{
    public static SpellDatabase getInstance;
    void Awake() { getInstance = this; }

    [SerializeField] Spell[] spells;

    public Spell getSpell(int id)
    {
        Debug.Log("Searching for spell with id: " + id);
        for (int i = 0; i < spells.Length; i++)
        {
            if (spells[i].ID == id)
                return spells[i];
        }

        return null;
    }
}