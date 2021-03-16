using UnityEngine;
using UnityEngine.UI;

public class SpellSlot : MonoBehaviour
{
    [SerializeField] Spell spell;
    [SerializeField] Button btn;

    private void Start()
    {
        btn.onClick.AddListener(delegate
        {
            Vector2Int target = GridManager.Instance.m_HoveredGridTile.m_GridPosition;
            _Player.local.CmdSetSpell(spell.ID, target.x, target.y, false);
        });
    }
  
}